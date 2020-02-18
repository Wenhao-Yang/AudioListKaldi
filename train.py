from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import pathlib
import pdb
import random
import argparse
import sys
import time

import numpy as np
import tensorflow as tf
from tqdm import tqdm

import input_data_train as input_data
import model
import h5py

from tensorflow.python.platform import gfile

from input_data_test import eval_kaldi_eer

FLAGS = None


def main(_):
    tf.logging.set_verbosity(tf.logging.INFO)

    tf.set_random_seed(1234)

    sess = tf.InteractiveSession()
    #generate  an dictionary which indicate some settings of traitement audio
    audio_settings = input_data.prepare_audio_settings(
        FLAGS.sample_rate,
        FLAGS.duration_ms,
        FLAGS.window_size_ms,
        FLAGS.window_stride_ms,
        FLAGS.num_coefficient)

    # create an objet of class AudioProcessor. 
    lstm_model_setting={}
    lstm_model_setting['num_units'] = FLAGS.num_units
    lstm_model_setting['dimension_projection'] = FLAGS.dimension_projection
    lstm_model_setting['num_layers'] = FLAGS.num_layers

    # if skip_generate_feature=True,
    #it will not calcul the mfcc feature and not prepare the file trials for training or testing
    audio_data_processor = input_data.AudioProcessor(
        FLAGS.data_dir,
        FLAGS.num_repeats,
        audio_settings,
        FLAGS.skip_generate_feature,
        FLAGS.num_utt_enrollment)

    #hold a place for input of the neural network
    input_audio_data = tf.placeholder(tf.float32, [FLAGS.batch_size, 1+FLAGS.num_utt_enrollment, audio_settings['desired_spectrogramme_length'], FLAGS.num_coefficient],
        name='input_audio_data')

    # definit weight W and bias B for the linear layer on top of the LSTM
    dimension_linear_layer = FLAGS.dimension_linear_layer
    weights = tf.Variable(tf.random_normal([FLAGS.dimension_projection, dimension_linear_layer], stddev=1), name='weights')
    bias = tf.Variable(tf.random_normal([dimension_linear_layer], stddev=1), name='bias')
    dropout_prob_input = tf.placeholder(tf.float32, [], name='dropout_prob_input')

    l_weight = tf.Variable(tf.random_normal([], stddev=1), name='l_weight')
    l_bias = tf.Variable(tf.random_normal([], stddev=1), name='l_weight')

    #  output of the model
    if FLAGS.model_architechture == 'lstm_baseline':
        outputs = model.create_lstm_baseline_model(
            audio_tuple_input=input_audio_data,
            W=weights,
            B=bias,
            lstm_model_setting=lstm_model_setting,
            dropout_prob=dropout_prob_input)

    # hold the place for label: 0:nontarget  1:target
    labels = tf.placeholder(tf.int64, [FLAGS.batch_size], name='labels')

    # check Nan or other numeriical errors
    control_dependencies = []
    if FLAGS.check_nans:
        checks = tf.add_check_numerics_ops()
        control_dependencies = [checks]

    #get the loss 
    #weight_scalar = tf.Variable(1.0, name='weight_scalar')
    #bias_scalar = tf.Variable(0.1, name='bias_scalar')
    with tf.name_scope('train_loss'):
        loss = model.my_tuple_loss(batch_size=FLAGS.batch_size*2,
                                   tuple_size=1+FLAGS.num_utt_enrollment,
                                   spk_representation=outputs,
                                   labels=labels,
                                   l_weight=l_weight,
                                   l_bias=l_bias)

        eval_info = model.eval_batch(batch_size=FLAGS.batch_size * 2,
                                     tuple_size=1 + FLAGS.num_utt_enrollment,
                                     spk_representation=outputs,
                                     labels=labels,
                                     l_weight=l_weight,
                                     l_bias=l_bias)

    tf.summary.scalar('train_loss', loss)
    tf.summary.scalar('train_eer', eval_info[0])

    with tf.name_scope('train'), tf.control_dependencies(control_dependencies):
        initial_learning_rate = FLAGS.learning_rate  # 初始学习率
        global_step = tf.Variable(0, trainable=False)
        # learning_rate_input = tf.placeholder(tf.float32, name='learning_rate_input')
        learning_rate = tf.train.polynomial_decay(initial_learning_rate,
                                                  global_step=global_step,
                                                  decay_steps=1200,
                                                  cycle=True,
                                                  end_learning_rate=0.0001)

        # learning_rate_input = tf.placeholder(tf.float32, name='learning_rate_input')
        train_step = tf.train.AdamOptimizer(learning_rate=learning_rate).minimize(loss, global_step=global_step)

    saver = tf.train.Saver(tf.global_variables())

    #merge all the summaries
    merged_summaries = tf.summary.merge_all()
    train_writer = tf.summary.FileWriter(FLAGS.data_dir + '/logs', sess.graph)
    # training loop
    tf.global_variables_initializer().run()
    #save graph
    tf.train.write_graph(sess.graph_def, FLAGS.data_dir, FLAGS.model_architechture + '.pbtxt')
    
    read_mfcc_buffer = h5py.File(FLAGS.data_dir + '/feature_mfcc.h5', 'r')
    read_trials_p = open(FLAGS.data_dir + '/trials_positive', 'r')
    read_trials_n = open(FLAGS.data_dir + '/trials_negative', 'r')

    # number of trials positive == number of trials negative
    # train_step is positive line / batch
    all_trials_p = read_trials_p.readlines()
    all_trials_n = read_trials_n.readlines()
    max_training_step = (int(len(all_trials_p)/FLAGS.batch_size)) * 2
    max_training_step = int(max_training_step/2)           ######################3#######

    # tf.logging.info('Total steps %5d: ', max_training_step)
    for training_step in range(max_training_step):

        if training_step%2 == 0:
        #samples positive
            trials_p = all_trials_p[int(training_step/2)*FLAGS.batch_size:(int(training_step/2)+1)*FLAGS.batch_size]
            train_voiceprint_p, label_p = audio_data_processor.get_data(trials_p, read_mfcc_buffer, 1)  # get one batch of tuples for training
            train_voiceprint = train_voiceprint_p
            label = label_p
        else:
            trials_n = all_trials_n[int((training_step - 1) / 2) * FLAGS.batch_size:(int(
                (training_step - 1) / 2) + 1) * FLAGS.batch_size]
            train_voiceprint_n, label_n = audio_data_processor.get_data(trials_n, read_mfcc_buffer, 0)   # get one batch of tuples for training
            train_voiceprint = train_voiceprint_n
            label = label_n

        # train_voiceprint = np.concatenate((train_voiceprint_p, train_voiceprint_n), axis=0)
        # label = np.concatenate((label_p, label_n), axis=0)

        #shape of train_voiceprint: (tuple_size, feature_size)    
        #shape of  label:  (1)
        train_summary, train_loss, train_info, _ = sess.run([merged_summaries, loss, eval_info, train_step],
                                                feed_dict={input_audio_data: train_voiceprint,
                                                           labels: label,
                                                           # learning_rate_input: FLAGS.learning_rate,
                                                           dropout_prob_input: FLAGS.dropout_prob})

        train_writer.add_summary(train_summary, training_step)

        cos_eer, cos_thre, p_cos_eer, p_cos_thre = train_info
        # print("accuracy:", sess.run(accuracy, feed_dict={x: mnist.test.images, y_actual: mnist.test.labels})
        if training_step % FLAGS.log_interval == 0:
            tf.logging.info('Current step [%5d]/[%5d]: loss %f, eer: %.4f%%, linear eer: %.4f%%' % (training_step, max_training_step,train_loss, cos_eer, p_cos_eer))

        if training_step % FLAGS.test_interval == 0:
            trials_p = all_trials_p[int(training_step / 2) * FLAGS.batch_size / 2:(int(
                training_step / 2) + 1) * FLAGS.batch_size / 2]
            train_voiceprint_p, label_p = audio_data_processor.get_data(trials_p, read_mfcc_buffer,
                                                                        1)  # get one batch of tuples for training
            trials_n = all_trials_n[int((training_step - 1) / 2) * FLAGS.batch_size / 2:(int(
                (training_step - 1) / 2) + 1) * FLAGS.batch_size / 2]
            train_voiceprint_n, label_n = audio_data_processor.get_data(trials_n, read_mfcc_buffer,
                                                                        0)  # get one batch of tuples for training
            test_voiceprint = np.concatenate((train_voiceprint_p, train_voiceprint_n), axis=0)
            test_label = np.concatenate((label_p, label_n), axis=0)

            test_dict = {input_audio_data: test_voiceprint, labels: test_label, dropout_prob_input: 0.}
            test_info = sess.run(eval_info, feed_dict=test_dict)
            cos_eer, cos_thre, p_cos_eer, p_cos_thre = test_info
            tf.logging.info('Test eer: %.4f%%, linear eer: %.4f%%' % (cos_eer, p_cos_eer))

        #save  the model final
        if training_step == (max_training_step - 1) or (training_step+1)%500 == 0:
            times = time.strftime("%Y-%m-%d-%H:%M:%S", time.localtime())
            save_path = os.path.join(FLAGS.checkpoint_dir, FLAGS.model_architechture, '%s.ckpt'%(times))

            save_path_ob = pathlib.Path(save_path)
            if not save_path_ob.parent.exists():
                os.makedirs(str(save_path_ob.parent))

            tf.logging.info('Saving to "%s-%d"', save_path, training_step)
            saver.save(sess, save_path, global_step=training_step)

    read_mfcc_buffer.close()
    read_trials_n.close()
    read_trials_p.close()

if __name__ == '__main__':
    pwd = os.getcwd()
    parser = argparse.ArgumentParser()
    parser.add_argument('--sample_rate', type=int, default=16000, help='sample rate of the wavs')
    parser.add_argument('--duration_ms', type=int, default=2000, help='duration of wavs used for training' )
    parser.add_argument('--window_size_ms', type=int, default=25, help='how long each frame of spectrograme')
    parser.add_argument('--window_stride_ms', type=int, default=10, help='how far to move in time between two frames')
    parser.add_argument('--num_coefficient', type=int, default=40, help='numbers of coefficients of mfcc')
    parser.add_argument('--data_dir', type=str, default='data/CN-Celeb/dev/', help='work location')
    parser.add_argument('--checkpoint_dir', type=str, default='data/CN-Celeb/checkpoint/', help='work location')
    parser.add_argument('--num_repeats', type=int, default=240, help='number of repeat when we prepare the trials')
    parser.add_argument('--skip_generate_feature', type=bool, default=True, help='whether to skip the phase of generating mfcc features')
    parser.add_argument('--num_utt_enrollment', type=int, default=5, help='numbers of enrollment utts for each speaker')
    parser.add_argument('--check_nans', type=bool, default=True, help='whether to check for invalid numbers during processing')
    parser.add_argument('--model_architechture', type=str, default='lstm_baseline')
    parser.add_argument('--num_units', type=int, default=128, help='numbers of units for each layer of lstm')
    parser.add_argument('--dimension_projection', type=int, default=64, help='dimension of projection layer of lstm')
    parser.add_argument('--num_layers', type=int, default=3, help='number of layers of multi-lstm')
    parser.add_argument('--dimension_linear_layer', type=int, default=64, help='dimension of linear layer on top of lstm')
    parser.add_argument('--learning_rate', type=float, default=0.001)
    parser.add_argument('--dropout_prob', type=float, default=0.05)
    parser.add_argument('--batch_size', type=int, default=80)
    parser.add_argument('--log-interval', type=int, default=1)
    parser.add_argument('--test-interval', type=int, default=4)

    FLAGS, unparsed = parser.parse_known_args()
    tf.app.run(main=main, argv=[sys.argv[0]] + unparsed)
