from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import math
import pdb
import numpy as np
import tensorflow as tf

from input_data_test import eval_kaldi_eer


def unit_lstm(num_units, dimension_projection, dropout_prob):
    lstm_cell = tf.contrib.rnn.LSTMCell(num_units=num_units,
        num_proj=dimension_projection,
        state_is_tuple=True)
    lstm_cell = tf.nn.rnn_cell.DropoutWrapper(lstm_cell,
        output_keep_prob=1-dropout_prob)

    return lstm_cell


def create_lstm_baseline_model(audio_tuple_input, W, B,
                               lstm_model_setting,
                               dropout_prob):
    '''
    audio_tuple_input: shape:    (bash_size, tuple_size=num_utt_enrollment+1, time_steps, num_features)
    '''
    #reshape inputdata
    shape_input_data = audio_tuple_input.shape
    batch_size = shape_input_data[0]
    tuple_size = shape_input_data[1]
    time_steps = shape_input_data[2]
    feature_size = shape_input_data[3]

    X = tf.reshape(audio_tuple_input, [batch_size*tuple_size, time_steps, feature_size])
    XT = tf.transpose(X, [1, 0, 2])
    #XT:  (time_steps, batchsize*tuplesize, featuresize)

    XR = tf.reshape(XT, [-1, feature_size])
    #XR: (batchsize*tuplesize*timesteps, featuressize)

    X_split = tf.split(XR, time_steps, 0)
    # X_split:   timesteps arrays, each array has the dimension
    #  (bashsize*tuplesize,featuresize)

    #definit lstm
    num_units = lstm_model_setting['num_units'] # 128
    dimension_projection = lstm_model_setting['dimension_projection'] # 64
    num_layers = lstm_model_setting['num_layers'] # 3
    mult_lstm = tf.nn.rnn_cell.MultiRNNCell([unit_lstm(num_units, dimension_projection, dropout_prob) for i in range(num_layers)],
        state_is_tuple=True)

    #get output of lstm
    outputs, _states = tf.contrib.rnn.static_rnn(mult_lstm, X_split, dtype=tf.float32)

    #dimension of output:  timesteps arrays
    #and each arrays has dimension: (batchsize*tuplesize, outputsize) 
    # we just want to take the output of last layer

    return tf.matmul(outputs[-1], W) + B
    #shape:   (batchsize*tuplesize, dimension_linear_layer)

def my_tuple_loss(batch_size, tuple_size, spk_representation, labels, l_weight, l_bias):
    '''
    this function can calcul the tuple loss for a batch
    spk_representation:    (bashsize*tuplesize, dimension of linear layer)
    labels:                 0/1
    weight and bias are scalar
    '''

    feature_size = spk_representation.shape[1]
    w = tf.reshape(spk_representation, [batch_size, tuple_size, feature_size])

    loss = 0
    for indice_bash in range(batch_size):
        # vec[1:] is enroll vectors
        wi_enroll = w[indice_bash, 1:]    # shape:  (tuple_size-1, feature_size)

        # vec[0] is eval vectors
        wi_eval = w[indice_bash, 0]

        # normalize all vectors and avg enroll
        normlize_wi_enroll = tf.nn.l2_normalize(wi_enroll, axis=1)
        c_k = tf.reduce_mean(normlize_wi_enroll, 0)              # shape: (feature_size)
        normlize_ck = tf.nn.l2_normalize(c_k, dim=0)
        normlize_wi_eval = tf.nn.l2_normalize(wi_eval, axis=0)

        # compute cos(enroll_avg, eval)
        cos_similarity = tf.reduce_sum(tf.multiply(normlize_ck, normlize_wi_eval))

        score = cos_similarity
        p_score = tf.add(tf.multiply(-l_weight, score), -l_bias)
        # pdb.set_trace()
        label = tf.cast(labels[indice_bash], dtype=tf.float32)
        loss_one = tf.multiply(label, tf.log(tf.sigmoid(p_score)))
        loss_zero = tf.multiply((1-label), tf.log((1 - tf.sigmoid(p_score))))
        loss += loss_one + loss_zero

    return -loss/batch_size

    # return tf.cond(tf.equal(labels, 1), f1, f2)


def eval_batch(batch_size, tuple_size, spk_representation, labels, l_weight, l_bias):
    '''
    this function can calcul the eer for a batch
    spk_representation:    (bashsize*tuplesize, dimension of linear layer)
    labels:                 [0/1]s
    weight and bias are scalar
    '''

    feature_size = spk_representation.shape[1]
    w = tf.reshape(spk_representation, [batch_size, tuple_size, feature_size])

    cos_score = []
    p_cos_score = []
    cos_label = []
    for indice_bash in range(batch_size):
        # vec[1:] is enroll vectors
        wi_enroll = w[indice_bash, 1:]    # shape:  (tuple_size-1, feature_size)
        # vec[0] is eval vectors
        wi_eval = w[indice_bash, 0]

        # normalize all vectors and avg enroll
        normlize_wi_enroll = tf.nn.l2_normalize(wi_enroll, axis=1)
        c_k = tf.reduce_mean(normlize_wi_enroll, 0)              # shape: (feature_size)
        normlize_ck = tf.nn.l2_normalize(c_k, dim=0)
        normlize_wi_eval = tf.nn.l2_normalize(wi_eval, axis=0)

        # compute cos(enroll_avg, eval)
        cos_similarity = tf.reduce_sum(tf.multiply(normlize_ck, normlize_wi_eval))

        label = tf.cast(labels[indice_bash], dtype=tf.float32)
        cos_label.append(tf.reshape(label, []))

        score = cos_similarity
        cos_score.append(tf.reshape(score, []))

        p_score = tf.add(tf.multiply(-l_weight, score), -l_bias)
        p_cos_score.append(tf.reshape(p_score, []))

    # cos_score = np
    cos_eer, cos_thre = eval_kaldi_eer(cos_score, cos_label, cos=True, re_thre=True)
    p_cos_eer, p_cos_thre = eval_kaldi_eer(p_cos_score, cos_label, cos=True, re_thre=True)

    return (cos_eer, cos_thre, p_cos_eer, p_cos_thre)


def tuple_loss(batch_size, tuple_size, spk_representation, labels):
    '''
    this function can calcul the tuple loss for a batch
    spk_representation:    (bashsize*tuplesize, dimension of linear layer)
    labels:                 0/1
    weight and bias are scalar
    '''

    feature_size = spk_representation.shape[1]
    w = tf.reshape(spk_representation, [batch_size, tuple_size, feature_size])
    def f1():
        loss = 0
        for indice_bash in range(batch_size):
            # vec[1:] is enroll vectors
            wi_enroll = w[indice_bash, 1:]    # shape:  (tuple_size-1, feature_size)

            # vec[0] is enroll vectors
            wi_eval = w[indice_bash, 0]

            # normalize all vectors and avg enroll
            normlize_wi_enroll = tf.nn.l2_normalize(wi_enroll, dim=1)
            c_k = tf.reduce_mean(normlize_wi_enroll, 0)              # shape: (feature_size)
            normlize_ck = tf.nn.l2_normalize(c_k, dim=0)
            normlize_wi_eval = tf.nn.l2_normalize(wi_eval, dim=0)

            # compute cos(enroll_avg, eval)
            cos_similarity = tf.reduce_sum(tf.multiply(normlize_ck, normlize_wi_eval))

            score = cos_similarity
            loss += tf.sigmoid(score)
        return -tf.log(loss/batch_size)

    def f2():   #nontarget
        loss = 0
        for indice_bash in range(batch_size):
            wi_enroll = w[indice_bash, 1:]    # shape:  (tuple_size-1, feature_size)
            wi_eval = w[indice_bash, 0]
            normlize_wi_enroll = tf.nn.l2_normalize(wi_enroll, dim=1)
            c_k = tf.reduce_mean(normlize_wi_enroll, 0)              # shape: (feature_size)
            normlize_ck = tf.nn.l2_normalize(c_k, dim=0)
            normlize_wi_eval = tf.nn.l2_normalize(wi_eval, dim=0)

            cos_similarity = tf.reduce_sum(tf.multiply(normlize_ck, normlize_wi_eval))
            score = cos_similarity

            loss += (1 - tf.sigmoid(score))
        return -tf.log(loss/batch_size)

    return tf.cond(tf.equal(labels, 1), f1, f2)



