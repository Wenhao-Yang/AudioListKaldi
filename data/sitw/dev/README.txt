#
# Author: Mitchell McLaren Dec 23,2015
# Contact: sitw_poc@speech.sri.com
# SRI International
#

The Speakers in the Wild (SITW) development data set

--- About the database ---
The Speakers in the Wild (SITW) speaker recognition challenge
(SRC) is intended to support research toward the real-world application
of automatic speaker recognition technology across speech
acquired in unconstrained conditions. The SITW SRC will serve to
benchmark current technologies in both single and multi-speaker audio
with the dataset and annotations being made publicly available after the
challenge (under research-only license) to facilitate continued development by
participants and support for new research groups entering the field
of automatic speaker recognition.

The SITW challenge is designed to offer both the traditional
style trials (i.e., voice comparisons) involving single-speaker enrollment
and test audio, as well as multi-speaker enrollment and test
audio. Enrollment from multi-speaker audio is enabled with a small
amount of ground truth annotation indicating where the speaker of interest
speaks. This latter case is inspired by the case of minimizing the otherwise
labor intensive task of user annotation for enrolling a speaker
from a multi-speaker audio file.

The SITW speech data was collected from open-source media
channels in which several hundred well-known public figures, or persons
of interest (POI), were present and speaking. Specifically, considerable
mismatch in terms of audio conditions was sought where
speech from each POI was acquired in both high-quality studiobased
interviews, and raw audio captured on, for instance, a camcorder.
Duration of speech for each speaker is unconstrained, as are
the audio conditions. All noise, reverb, vocal effort, and other acoustic
artifacts in the SITW data were due to the audio recording conditions
and location with no artificially created artifacts. Speaking
conditions include monologues, interviews, and more conversational
dialogues with dominant backchannel and speaker overlap.


--- The development data set ---
The development portion of SITW includes annotations for 50 unique speakers. 
It is intended to be used to develop and tune speaker recognition systems and
algorithms for handling the conditions of multi-speaker data of SITW. Such
systems can then be applied to the evaluation portion of SITW which contains a
disjoint set of several hundred speakers.

The data is organized in the following folders:

- [audio] Folder containing all audio files coded as singlechannel,
16-bit FLAC audio files at a 16kHz sampling rate.

- [keys] Folder containing the keys for each of the trial lists in the ‘lists’ folder.
The naming convention withh follow {enrolcnd}-{testnd}*.lst. Additionally, metadata associated
with audio files and unique speaker labels are provided in 'meta.lst'.

    A subfolder [aux] includes keys that can be used to subset a set of trials in a given trial condition
    to better analyze aspects of the system. For instance assist-multi.10s.lst
    provides a subset of enrolled models to those using 10second annotations of
    where the POI speaks. Similar keys allow for the analysis of annotation duration
    on the same set of tests and same core enrollment samples.

- [lists] Folder containing lists indicating POI enrollment details, test segment lists and trial lists.

    *Enrollment lists: There will three enrollment lists corresponding to the three enrollment conditions.
    The first, enroll-core.lst, contains two columns; a POI model name and the corresponding audio file with which to enroll the POI.

    The enroll-assist.lst and enroll-assistclean.lst each contain four columns; a POI model name, the audio file with which POI
    speech is located, and a start and end time in seconds indicating the annotated segment in which the POI speaks. An example
    would be ‘69006 audioenrol/lywwa.flac 72.000 77.310’.

    *Test lists: There will be two test lists, test-core.lst and test-multi.lst, each indicating
    the filenames of test segments including the audio foldername such as ‘audio-test/akyvw.flac’.

    * Trial lists: There will be six trial lists corresponding to each trial condition. Trial lists will be named according
    to the conditions, trial.{enrol}-{test}.lst, such as trial.core-core.lst. A trial list consists
    of two columns; a POI model name and the test file.

--- Meta data ---
The fields of ./keys/meta.lst are detailed below.

An example line of meta.lst to assist in understanding fields below:
    path              spkname gender microphone session-ID start-time end-time numofspk artifact-labels
    "audio/skdts.flac ZPYJ    m      video      605273     96         120      1        codec,reverb

    level(0-4 -> clean2degraded) environment metadata-perceived
    3                            interview   laughter,overlap"

(1) audio file name from within the 'dev' root
(2) speaker ID
(3) gender of the speaker
(4) microphone type used by speaker ID
(5) session ID (unique to orignal open-source video)
(6) audio segment start time (sec) from original sessionID
(7) audio segment end time (sec) from original sessionID
(8) number of speakers in the audio file (a '+' indicates potential for more speakers in a segment used for enrolment)
(9) artifact labels (comma delimted) observed in the longest segment from this session ID
(10) level (0-4 --> clean to degraded) of most dominant perceived artifact labels
(11) recording environment or scenario
(12-->) metadata perceived for longest segment from the session ID

Note that the perceived metadata of fields 9 onwards were judged based on the longest segment from the session ID that also exists in the core enrollment or test lists. This is because audio used for the assist condition was only scanned rather than listened to (see the evaluation plan for more details).
Also note that each unique file name is tied to a speaker ID. There are audio files that contain the same content due to having more than one person of interest in them. For example, session ID 762983 has two POI speaking in the cut from 40s to 179s but two unique files since they are based on speaker and session:

$ grep "762983 40 179" ./keys/meta.lst
audio/agiwn.flac PNTR f studio 762983 40 179 3 clean 0 interview laughter
audio/uknkl.flac UZCG f studio 762983 40 179 3 clean 0 interview laughter

--- md5sum ---
Validation of downloaded audio can be performed using ./lists/audio_md5sum.lst
