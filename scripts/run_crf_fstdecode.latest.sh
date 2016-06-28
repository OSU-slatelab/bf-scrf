#!/bin/bash

set -e
set -o pipefail

input_arg=`echo $0 $@`

. /u/drspeech/share/lib/icsiargs.sh

ASRCRAFTBASE=/u/drspeech/opt/ASR-CRaFT/
ICSIPATH=/u/drspeech/opt/icsi-scenic/20110715a/x86_64/bin/
#PATH=$ASRCRAFTBBASE/v0.01h/bin/:$ASRCRAFTBASE/helper/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01i/:$ASRCRAFTBASE/helper/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01j_NewDurRep/:$ASRCRAFTBASE/helper/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01j_NewDurRep/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01k_segmental/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01l_segmental_WithoutDurLab/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01m_all_segmental_model/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01l_all_segmental_model_with_boundary_feature_fast_model/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01l_all_segmental_model_with_boundary_feature_fast_model/fast_model_no_mem_leak_with_init_iter/:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01o_individual_segmental_features/sample-avg-max-min-dur_debugNStateDecodeFst:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01o_individual_segmental_features/sample-avg-max-min-dur_debugNStateSegDecodeFst:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01u_nstate_segmental_correct_fstdecode_all_one_file:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01v_nstate_segmental_correct_maxv_all_one_file:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01w_nstate_segmental_done_file:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
PATH=/data/data2/hey/SegmentalCRF/bin/ASR-CRaFT_v0.01.latest:$ASRCRAFTBASE/helper/:/data/data2/hey/SegmentalCRF/misc/:$ICSIPATH:$PATH; export PATH
#LD_LIBRARY_PATH=/u/drspeech/opt/OpenFst-1.1/x86_64/lib/:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH
LD_LIBRARY_PATH=/u/drspeech/opt/OpenFst-beta-20080317/fst/lib/:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

USAGE="Usage:

$0
  argfile=[arg file, default=./conf]
  lr=[learning rate]
  eta=[AdaGrad scaling factor, default=1.0. Only one of eta and lr can be set, based on whether to use AdaGrad.]
  wt_pre=[weight dir]
  SEGMODEL=[stdframe(default)|stdseg|stdseg_no_dur|stdseg_no_dur_no_transftr|stdseg_no_dur_no_segtransftr]
  start=[start iter, default=0]
  end=[end iter, default=the last available iteration]
  step=[iter step, default=1]
  testsets=[\"cv core\"(default)|cv|dt|et|core|enh|...]
  nj=[number of jobs, default is 1]
  mem=[memory requirement, default=nj*938 (MB), optional]
  nodes=[machines to allocate the jobs, e.g. feldspar, optional]
  autoresume=[1(default)|0]
  skipdecode=[0(default)|1]
"

if [ ! -z "$1" ] && [ "$1" == "-h" ]; then
  echo "$USAGE"
  exit
fi

if [ -z "$argfile" ]; then
  argfile=conf
  echo "The arg file argument is not set, using default: $argfile"
fi

if [ ! -f "$argfile" ]; then
  echo "Error: cannot access the argfile: $argfile" 1>&2
  exit 1
fi

. $argfile

if [ ! -z "$lr" ] && [ -z "$eta" ]; then
  grad_opt="crf_lr=$lr"
elif [ -z "$lr" ] && [ ! -z "$eta" ]; then
  grad_opt="crf_use_adagrad=true crf_adagrad_eta=$eta"
else
  echo "Either lr or eta has to be set, but cannot be both set."
  echo "$USAGE"
  exit 1
fi

if [ -z "$wt_pre" ]; then
  wt_pre=./weights
  echo "wt_pre not defined, using default of $wt_pre"
fi

if [ -z "$testsets" ]; then
  testsets="cv core"
  echo "dataset not defined, using default: cv core"
fi

if [ -z "$nj" ]; then
  nj=1
  echo "nj is set to default: 1"
fi

if [ -z "$mem" ]; then
  mem=$((nj * 938)) # MB
  echo "mem is set to default: $mem"
fi

[ ! -z "$nodes" ] && nodes_opt="-w $nodes" || nodes_opt=

if [ -z "$autoresume" ]; then
  autoresume=1
  echo "autoresume is set to default: 1"
else
  if [ "$autoresume" != "1" ] && [ "$autoresume" != "0" ]; then
    echo "Error: autoresume has to be 1 or 0" 1>&2
    exit 1
  fi
fi

if [ -z "$skipdecode" ]; then
  skipdecode=0
  echo "skipdecode is set to default: 0"
else
  if [ "$skipdecode" != "1" ] && [ "$skipdecode" != "0" ]; then
    echo "Error: skipdecode has to be 1 or 0" 1>&2
    exit 1
  fi
fi

if [ -z "$MAXDUR" ]; then
  MAXDUR=1
fi

if [ -z "$ACTUALLABS" ]; then
  ACTUALLABS=$NUML
fi

if [ -z "$FEAF1_WINLEN" ]; then
  FEAF1_WINLEN=$MAXDUR
fi

if [ -z "$FEAF2_WINLEN" ]; then
  FEAF2_WINLEN=$FEAF1_WINLEN
fi

if [ -z "$FEAF3_WINLEN" ]; then
  FEAF3_WINLEN=$FEAF1_WINLEN
fi

if [ -z "$WINEXTENT" ]; then
  WINEXTENT=$MAXDUR
fi

if [ -z "$SEGMODEL" ]; then
  SEGMODEL="stdframe"
fi

if [ ! -z "$lr" ]; then
  WBASE=$wt_pre.lr$lr
else
  WBASE=$wt_pre.ag_eta$eta
fi

OTAIL=$NUML\labs.$NUMS\feas

if [ -z "$start" ]; then
  start=0
fi

if [ -z "$step" ]; then
  step=1
fi

if [ -z "$end" ]; then
  i=$start
  while [ -f $WBASE/.done.train.i$i ]; do
    i=$[$i+$step]
  done
  end=$[$i-$step]
fi

echo "start: $start, step: $step, end: $end"

for i in `seq $start $step $end`; do

  echo iteration $i

  for dataset in $testsets; do

    echo dataset $dataset

    dataset_uc=`echo $dataset | awk '{print toupper($0)}'`

    if [ ! -z "$lr" ]; then
      TESTBASE=$WBASE/${dataset}_out.lr$lr
    else
      TESTBASE=$WBASE/${dataset}_out.ag_eta$eta
    fi
    echo "Using output weight directory $WBASE"

    LOGF=$WBASE/crf.fstdecode.$dataset.log

    #if [ ! -d $TESTBASE ]; then
    #  mkdir $TESTBASE
    #fi

    DATASET_FEAF1=$(eval echo \$${dataset_uc}_FEAF1)
    DATASET_FEAF2=$(eval echo \$${dataset_uc}_FEAF2)
    DATASET_FEAF3=$(eval echo \$${dataset_uc}_FEAF3)
    DATASET_START=$(eval echo \$${dataset_uc}_START)
    DATASET_END=$(eval echo \$${dataset_uc}_END)
    DATASET_OLIST=$(eval echo \$${dataset_uc}_OLIST)
    DATASET_REFMLF=$(eval echo \$${dataset_uc}_REFMLF)

    WF=$WBASE/$WFPREFIX.i$i.avg.out
    ODIR=$TESTBASE/$i\iters
    OUTF=$ODIR/crf.$i.$OTAIL.ilab
    MLF=$ODIR/crf.$i.$OTAIL.mlf
    MAP39MLF=$ODIR/crf.$i.$OTAIL.map39.mlf
    SINGLESTATEMLF=$ODIR/crf.$i.$OTAIL.1state.mlf

    OUTPHNTXT=$ODIR/crf.$i.$OTAIL.phn.lab.ascii
    OUTDURTXT=$ODIR/crf.$i.$OTAIL.dur.lab.ascii

    [ "$autoresume" -eq 1 ] && [ -f $ODIR/.done ] && continue

    if [ ! -f $WF ]; then
      echo "Error: weight file does not exist: $WF" 1>&2
      exit 1
    fi

    mkdir -p $ODIR

    echo "Using $WF"

    if [ "$skipdecode" == 0 ]; then
      
      echo "Building $OUTF"
      
      which CRFFstDecode

      echo `date` 2>&1 | tee -a $LOGF
      echo $input_arg 2>&1 | tee -a $LOGF
      echo "CRFFstDecode \
	ftr1_file=$DATASET_FEAF1 \
	ftr1_window_len=$FEAF1_WINLEN \
	ftr1_left_context_len=$FEAF1_LEFT_CTX \
	ftr1_right_context_len=$FEAF1_RIGHT_CTX \
	ftr1_extract_seg_ftr=$FEAF1_EXTRACT_SEG_FTR \
	ftr2_file=$DATASET_FEAF2 \
	ftr2_window_len=$FEAF2_WINLEN \
	ftr2_left_context_len=$FEAF2_LEFT_CTX \
	ftr2_right_context_len=$FEAF2_RIGHT_CTX \
	ftr2_extract_seg_ftr=$FEAF2_EXTRACT_SEG_FTR \
	ftr3_file=$DATASET_FEAF3 \
	ftr3_window_len=$FEAF3_WINLEN \
	ftr3_left_context_len=$FEAF3_LEFT_CTX \
	ftr3_right_context_len=$FEAF3_RIGHT_CTX \
	ftr3_extract_seg_ftr=$FEAF3_EXTRACT_SEG_FTR \
	window_extent=$WINEXTENT \
	weight_file=$WF \
	label_maximum_duration=$MAXDUR \
	num_actual_labs=$ACTUALLABS \
	crf_label_size=$NUML \
	crf_eval_range=$DATASET_START-$DATASET_END \
	crf_states=$NSTATES \
	crf_model_type=$SEGMODEL \
	crf_output_labelfile=$OUTF \
	crf_stateftr_start=$STATE_FTR_START \
	crf_stateftr_end=$STATE_FTR_END \
	crf_transftr_start=$TRANS_FTR_START \
	crf_transftr_end=$TRANS_FTR_END \
	$DECODE_ARGS" 2>&1 | tee -a $LOGF

      srun -c $nj --mem=$mem $nodes_opt \
      CRFFstDecode \
	ftr1_file=$DATASET_FEAF1 \
	ftr1_window_len=$FEAF1_WINLEN \
	ftr1_left_context_len=$FEAF1_LEFT_CTX \
	ftr1_right_context_len=$FEAF1_RIGHT_CTX \
	ftr1_extract_seg_ftr=$FEAF1_EXTRACT_SEG_FTR \
	ftr2_file=$DATASET_FEAF2 \
	ftr2_window_len=$FEAF2_WINLEN \
	ftr2_left_context_len=$FEAF2_LEFT_CTX \
	ftr2_right_context_len=$FEAF2_RIGHT_CTX \
	ftr2_extract_seg_ftr=$FEAF2_EXTRACT_SEG_FTR \
	ftr3_file=$DATASET_FEAF3 \
	ftr3_window_len=$FEAF3_WINLEN \
	ftr3_left_context_len=$FEAF3_LEFT_CTX \
	ftr3_right_context_len=$FEAF3_RIGHT_CTX \
	ftr3_extract_seg_ftr=$FEAF3_EXTRACT_SEG_FTR \
	window_extent=$WINEXTENT \
	weight_file=$WF \
	label_maximum_duration=$MAXDUR \
	num_actual_labs=$ACTUALLABS \
	crf_label_size=$NUML \
	crf_eval_range=$DATASET_START-$DATASET_END \
	crf_states=$NSTATES \
	crf_model_type=$SEGMODEL \
	crf_output_labelfile=$OUTF \
	crf_stateftr_start=$STATE_FTR_START \
	crf_stateftr_end=$STATE_FTR_END \
	crf_transftr_start=$TRANS_FTR_START \
	crf_transftr_end=$TRANS_FTR_END \
	$DECODE_ARGS 2>&1 | tee -a $LOGF
      echo `date` 2>&1 | tee -a $LOGF

    fi # if [ "$skipdecode" == 0 ]

    #perl vit2mlf.pl olist=$OLIST vit=$OUTF > $MLF

    echo "$SEGMODEL"
    dur_opt=
    #if [ "$SEGMODEL" == "stdseg" -o "$SEGMODEL" == "stdseg_no_dur" -o "$SEGMODEL" == "stdseg_no_dur_no_transftr" -o "$SEGMODEL" == "stdseg_no_dur_no_segtransftr" ]; then
    if [ $MAXDUR -eq 1 ]; then
      labcat -ip ilab -op ascii $OUTF > $OUTPHNTXT
    else
      labcat -ip ilab -op ascii $OUTF | ilab_PhnDur2Phn.pl -m $PHNDURLABMAP > $OUTPHNTXT
      labcat -ip ilab -op ascii $OUTF | ilab_PhnDur2Dur.pl -m $PHNDURLABMAP > $OUTDURTXT
      dur_opt="-d $OUTDURTXT"
    fi
    #ilab2mlf.pl -s $SYMSF -o $DATASET_OLIST < $OUTPHNTXT > $MLF
    timit_score.new.sh -s $SYMSF -o $DATASET_OLIST -n $NSTATES $dur_opt $dataset $OUTPHNTXT

    #if [ $NSTATES == "3" ]; then
    #  #mapresults_3state_1state.pl <$MLF | map54to39.pl >$MAP39MLF
    #  mapresults_3state_1state.pl <$MLF >$SINGLESTATEMLF
    #elif [ $NSTATES == "1" ]; then
    #  ln -fsn `basename $MLF` $SINGLESTATEMLF
    #else
    #  echo "Error: NSTATES ($NSTATES) not equal to 1 or 3." 1>&2
    #  exit 1
    #fi

    ##map54to39.pl $MLF >$MAP39MLF
    #map54to39.pl $SINGLESTATEMLF >$MAP39MLF

    #HResults -I $DATASET_REFMLF /dev/null $MAP39MLF > $ODIR/${dataset}_results.txt

    touch $ODIR/.done

  done

done
