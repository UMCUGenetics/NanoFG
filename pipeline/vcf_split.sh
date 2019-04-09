#!/bin/bash

usage() {
echo "
Required parameters:
    -v|--vcf		    Path to vcf file

Optional parameters:
    -h|--help               Shows help
    -o|--outputdir                                                                Path to output directory
    -d|--split_directory        directory that contains NanoFG [$NANOFG_DIR]
    -l|--lines     Number of lines to put in each spit vcf file [Devides vcf in 50 files]
"
}

POSITIONAL=()

#DEFAULTS
OUTPUTDIR=$(realpath ./)
SPLITDIR=${OUTPUTDIR}/split_vcf

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
    -h|--help)
    usage
    exit
    shift # past argument
    ;;
    -v|--vcf)
    VCF="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--vcf)
    VCF="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--split_directory)
    SPLITDIR="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--lines)
    LINES="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z $VCF ]; then
    echo "Missing -v|--vcf parameter"
    usage
    exit
fi
if [ -z $LINES ]; then
  NUMBER_OF_SVS=$(grep -vc "^#" $VCF | grep -oP "(^\d+)")
  LINES=$(expr $NUMBER_OF_SVS / 100 + 1)
  if [ $LINES -lt 100 ]; then
    LINES=100
  fi
fi

echo `date`: Running on `uname -n`

VCF_NO_INS=${VCF/.vcf/_noINS.vcf}
VCF_NO_INS=${OUTPUTDIR}/$(basename $VCF_NO_INS)

grep "^#" $VCF > $VCF_NO_INS
grep -v "^#" $VCF | awk '$5!="<INS>"' >> $VCF_NO_INS

HEADER=$(grep "^#" $VCF_NO_INS)
AWK="grep -v \"^#\" $VCF_NO_INS | awk -v HEADER=\"\$HEADER\" 'NR%$LINES==1 { file = \"$SPLITDIR/\" int(NR/$LINES)+1 \".vcf\"; print HEADER > file } { print > file }'"
eval $AWK

echo `date`: Done
