#!/bin/bash
#----------------------------------------------------------
# CONFIG FOR SBATCH
#----------------------------------------------------------
#SBATCH -p Interactive
#SBATCH --account=lyonslab
#SBATCH -J upload
#SBATCH --output=sra_upload-%j-%A_%a.out
#SBATCH --mem 2G
#SBATCH -N 1
#SBATCH -n 10
#SBATCH -t 0-00:10

## notifications
#SBATCH --mail-user=buckleyrm@missouri.edu  # email address for notifications
#SBATCH --mail-type=BEGIN,END,FAIL  # which type of notifications to send
#----------------------------------------------------------

#----------------------------------------------------------
# CONFIG FOR JOB VAR
#----------------------------------------------------------

module load samtools/samtools-1.9-test
module load pigz/pigz-2.4

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
-c | --config=)
shift; CONFIG=$1
SM=$(cat $CONFIG | sed '2q;d' | awk {'print $1'}) # pulls out first row of config col 1
LB=$(echo $(cat $CONFIG | cut -f2) | sed 's/ /,/g') # pulls out entire col 2 and converts to comma sep values
PL=$(echo $(cat $CONFIG | cut -f3) | sed 's/ /,/g')
FC=$(echo $(cat $CONFIG | cut -f4) | sed 's/ /,/g')
LN=$(echo $(cat $CONFIG | cut -f5) | sed 's/ /,/g')
R1=$(echo $(cat $CONFIG | cut -f6) | sed 's/ /,/g')
R2=$(echo $(cat $CONFIG | cut -f7) | sed 's/ /,/g')
D1=$(echo $(cat $CONFIG | cut -f8) | sed 's/ /,/g')
D2=$(echo $(cat $CONFIG | cut -f9) | sed 's/ /,/g')
runLen=$(expr $(wc -l $CONFIG | cut -d" " -f1) - 1)
;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

sm=$SM

echo $sm

CWD=~/storage.lyonslab/sra_upload/upload1

mkdir $CWD/$sm

if [[ $(echo $D2 | cut -f2 -d",") = *".bam" ]]; then
lb=$(echo $LB | cut -f$2 -d",")
cat $CONFIG | tail -n+2 | cut -f8,9 | sed "s|/t|/|g" > $CWD/$sm/$sm.$lb.bam.list        

samtools cat -@ 10 -b $CWD/$sm/$sm.$lb.bam.list > $CWD/$sm/$sm.$lb.bam
samtools fastq -@ 10 -1 $CWD/$sm/$sm.$lb.R1.fq -2 $CWD/$sm/$sm.$lb.R2.fq $CWD/$sm/$sm.$lb.bam

else

for i in $(seq 2 $(( $runLen + 1 ))); do 
echo $i
d1=$(echo $D1 | cut -f$i -d",")
r1=$(echo $R1 | cut -f$i -d",")

d2=$(echo $D2 | cut -f$i -d",")
r2=$(echo $R2 | cut -f$i -d",")

lb=$(echo $LB | cut -f$i -d",")

pigz -dc -p 10 $d1/$r1.gz | head -n8 &>> $CWD/$sm/$sm.$lb.R1.fq  
pigz -dc -p 10 $d2/$r2.gz | head -n8 &>> $CWD/$sm/$sm.$lb.R2.fq
done

fi

pigz -p 10 $CWD/$sm/$sm.$lb.R1.fq
pigz -p 10 $CWD/$sm/$sm.$lb.R2.fq




