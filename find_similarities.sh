#Find out which disks contain similar files.


DIR=`dirname $0`
#find disks that aren't missing du.gz
disks=$(find -L . | grep /udevadm.disk.txt | sed s,/udevadm.disk.txt,, | while read f; do [ -z "`find -L $f -name du.gz`" ] || echo $f; done)

for a in $disks
do
	echo $(perl $DIR/parse_du.pl $(find -L $a|grep du.gz$) | grep '^   DEDUP' | head -n1) $a
	for b in $aa 
	do
		echo $(perl $DIR/parse_du.pl $(find -L $a $b|grep du.gz$) | grep '^   DEDUP' | head -n1) $a $b
	done
	aa="$aa $a"
done
