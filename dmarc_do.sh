#######################################
# Creator: Jonathan Garrido
# Email: jgrobles@protonmail.com
#
# Nov 4th, 2018
#
# Version: 1.0
#######################################
#!/bin/bash
#set -x

## Making sure the user uses the proper input.

if [[ $# -eq 0 ]] 
	then
	echo ' '
	echo "$(tput setaf 1)Usage: $(tput sgr0)./dmarc.sh + the_XML_file"
	echo ' '
	exit 1
fi

file $1|grep XML
if [[ $? -gt 0 ]] 
	then
	echo ' '
	echo 'Please try using a DMARC XML Report File'
	echo ' '
	exit 1
fi


## Grabbing most of the variables

SOURCE=$1
FROM=`grep org_name $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
BDATE=`grep begin $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
EDATE=`grep '<end>' $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
SENDER=`grep email $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
REPORT_ID=`grep report_id $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
YOURDOMAIN=`head -15 $SOURCE|grep domain |cut -d '>' -f2|cut -d '<' -f1`
OTHERDOMAINS=`grep domain $SOURCE |grep -v $YOURDOMAIN|cut -d '>' -f2|cut -d '<' -f1|sort|uniq|awk '{print}'`
PCT=`grep pct $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
ASPF=`grep aspf $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
ADKIM=`grep adkim $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
YOURIP=`grep source_ip $SOURCE |cut -d '>' -f2|cut -d '<' -f1|awk '{print}' ORS='/ '`
COUNTIP=`grep count $SOURCE |cut -d '>' -f2|cut -d '<' -f1|awk '{print}' ORS='/ '`
POLICY=`grep '<p>' $SOURCE |cut -d '>' -f2|cut -d '<' -f1`
SPFTEMP=`grep spf $SOURCE|grep -v aspf |cut -d '>' -f2|cut -d '<' -f1|egrep 'pass|fail'> /tmp/dmarc.spf`
DKIMTEMP=`grep dkim $SOURCE|cut -d '>' -f2|cut -d '<' -f1|egrep 'pass|fail'>/tmp/dmarc.dkim`



## Coloring SPF and DKIM


while read spf in
do
	if [ $spf == "pass" ] 
	then
		echo "$(tput setaf 2) $spf $(tput sgr0)" >> /tmp/dmarc.spf.ok
	else
	        echo "$(tput setaf 1) $spf $(tput sgr0)" >> /tmp/dmarc.spf.ok
	fi

done < /tmp/dmarc.spf


while read dkim in
do
	if [ $dkim == "pass" ] 
	then
		echo "$(tput setaf 2) $dkim $(tput sgr0)" >> /tmp/dmarc.dkim.ok
	else
	        echo "$(tput setaf 1) $dkim $(tput sgr0)" >> /tmp/dmarc.dkim.ok
	fi

done < /tmp/dmarc.dkim


SPF=`cat /tmp/dmarc.spf.ok|awk '{print}' ORS='/ '`
DKIM=`cat /tmp/dmarc.dkim.ok|awk '{print}' ORS='/ '`


## The beginning of printing


clear
echo "*******************************"
echo "*	DMARC Report V1.0     *"
echo "*******************************"

echo " "

echo "Report from: $FROM"
echo "Contact: $SENDER"

EXTRA=`grep extra_contact_info $SOURCE |cut -d '>' -f2|cut -d '<' -f1`

if [[ $? -eq 0 ]]
then
	echo "Extra Contact: $EXTRA"
else
	echo "Extra Contact: none"
fi

echo "Report ID: $REPORT_ID"
echo "Valid from: `date -d @$BDATE` to: `date -d @$EDATE`"

echo " "

echo "--------------------------------"
echo " "
echo "Your domain: $YOURDOMAIN"
echo " "

if [[ ! -z "$OTHERDOMAINS" ]]
then
	echo "Others Domains in the report: "
	echo $OTHERDOMAINS
fi

echo " "
echo "Percentaje: $(tput setaf 2)$PCT $(tput sgr0)"
echo " "

if [ $ASPF == 'r' ]
then
        echo "Alignment SPF: $(tput setaf 2)Relax $(tput sgr0)"
else
        echo "Alignment SPF: $(tput setaf 1)Strict $(tput sgr0)"
fi
echo " "


if [ $ADKIM == 'r' ]
then
        echo "Alignment DKIM: $(tput setaf 2)Relax $(tput sgr0)"
else
        echo "Alignment DKIM: $(tput setaf 1)Strict $(tput sgr0)"
fi
echo " "

echo "Policy: $POLICY"
echo " "

echo "Your IP(s): $YOURIP"
echo " "
echo "Count per IP(s): $COUNTIP"
echo " "
echo "SPF per IP(s): $SPF"
echo " "
echo "DKIM per IP(s): $DKIM"


#### Cleanning ####
rm /tmp/dmarc.spf
rm /tmp/dmarc.spf.ok
rm /tmp/dmarc.dkim.ok
rm /tmp/dmarc.dkim
