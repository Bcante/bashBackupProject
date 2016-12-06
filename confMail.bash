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


make -C /etc/mail
/etc/init.d/sendmail reload