parted /dev/sdb mklabel gpt
parted /dev/sdc mklabel gpt
parted /dev/sdb unit cyl mkpart xfs var 0 -1
parted /dev/sdc unit cyl mkpart xfs mongodb 0 -1
