#Requiert les droits sudo et sendmail (apt-get install sendmail mailutils sendmail-bin)
su
mkdir -m 700 /etc/mail/authinfo/
cd /etc/mail/authinfo/
info="AuthInfo: \"U:root\" \"I:$adress\" \"P:$pass\""
makemap hash gmail-auth < gmail-auth
cd ..

#Nombre de lignes que je dois garder
a=`wc -l < splittest`
a=$(($a - 3))

#Je découpe le fichier de configuration en deux fichiers (xaa et xbb)
split sendmail.mc -l $a
echo "define(`SMART_HOST\',`[smtp.gmail.com]')dnl" 
echo "define(`RELAY_MAILER_ARGS\', `TCP "'$h'" 587')dnl"
echo "define(`ESMTP_MAILER_ARGS\', `TCP "'$h'" 587')dnl"
echo "define(`confAUTH_OPTIONS\', `A p')dnl"
echo "TRUST_AUTH_MECH(\`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN\')dnl"
echo "define(`confAUTH_MECHANISMS\', `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl"
echo "FEATURE(`authinfo',`hash -o /etc/mail/authinfo/gmail-auth.db')dnl"


make -C /etc/mail
/etc/init.d/sendmail reload