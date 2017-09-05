



#	KHMAIL_AUTH_METH
#	
#	Esta variable indica el tipo de autentificacion que el smtp tiene para permitir
#	el envio de mail. Si no existe mecanismo de autentificacion debe dejarse sin cargar.
#	Si el mecanismo es validacion previa por POP3, debe cargarse la variable con el valor
#	POP3. Si el mecanismo es mediante SMTP PLAIN debe cargarse en la variable el valor
#	SMTP_PLAIN, y si el mecanismo es SMTP LOGIN debe cargarse en la variable el valor
#	SMTP_LOGIN. Con SMTP_PLAIN debe cargarse una variable adicional llamada
#	KHMAIL_SMTPPLAIN, y si se utiliza SMTP_LOGIN, deben cargarse dos variables mas, la
#	KHMAIL_SMTPLOGIN_USER y KHMAIL_SMTPLOGIN_PASS.

#	KHMAIL_SMTPPLAIN
#
#	Esta variable debe tener el valor en base 64 del usuario y la password de autentificacion
#	SMTP. Por ejemplo valiendose de Perlo la forma de calcularlo seria
#	perl -MMIME::Base64 -e 'print encode_base64("\000username\@dominio.net\000password")' 
#	y en la siguiete pagina web se puede encontrar un utilitario online para hacerlo
#	http://makcoder.sourceforge.net/demo/base64.php

#	KHMAIL_SMTPLOGIN_USER
#
#	Esta variable debe tener cargado en base64 el nombre de usuario con el cual se va a 
#	autentificar.

#	KHMAIL_SMTPLOGIN_PASS
#
#	Esta variable debe tener cargado en base64 la password del usuario KHMAIL_SMTPLOGIN_USER
#	con el cual se va a autentificar.


#	KHMAIL_POP3_PORT 
#
#	Esta variable debe cargarse con el numero de puerto del servicio POP3 en caso de que el
#	mecanismo de autentificacion es POP3. Recordar que el valor normal del puerto es 110.

#	KHMAIL_POP3_SERVER
#
#	Esta variable debe cargarse con la direccion IP (o nombre) del servidor POP3 en caso de
#	que la autentifiacion sea POP3.

#	KHMAIL_POP3_USER
#
#	Esta variable debe cargarse con el usuario de POP3 en caso que el mecanismo de autentifiacion
#	seleccionado sea POP3.

#	KHMAIL_POP3_PASS
#
#	Esta variable debe ser cargada con la password del usuario KHMAIL_POP3_USER en caso de que el 
#	mecanismo seleccionado sea POP3.

#	KHMAIL_SMTP_SERVER 
#
#	Esta variable debe cargarse con la direccion IP (o nombre) del servidor SMTP.

#	KHMAIL_SMTP_PORT  
#
#	Esta variable debe cargarse con el numero de puerto del servicio SMTP. Recordar que el valor
#	normal de este puerto es 25.

#	KHMAIL_HELO_SERVER 
#
#	Esta variable debe cargarse con la direccion IP o nombre del server que se hace conocer frente
#	al servidor SMTP desde el equipo que se envia el correo.

#	KHMAIL_FROM       
#
#	Esta variable debe cargarse con la cuenta de correo desde la que se indica que se enviara
#	el mail.

#	KHMAIL_TO_LIST     
#
#	Esta variable debe cargarse con las cuentas de correo (separadas por espacio en caso de ser mas
#	de uno) que son destinos del correo.

#	KHMAIL_SUBJECT      
#
#	Esta variable debe cargarse con el texto que es el subject del mail.

#	KHMAIL_BODY         
#
#	Esta variable debe cargarse con el path completo del archivo el cual su contenido sera el body del mail.

#	KHMAIL_SLEEP
#
#	Esta variablke debe cargarse con un numero que corresponde a la cantidad de segundos que se espera
#	entre la ejecucion de u comando en el server SMTP y otro comando. Si el server SMTP esta en la misma
#	red que la que ejecuta el script, el valor puede ser 1. Si en las mismas condiciones el server
#	sufre un uso intenso, el valor puede ser 2. Si al server nos conectamos mediante la web, el valor puede
#	ser 4.







#
# Funcion que se valida con el servicio POP3 para los mailservers
# que permiten enviar mail si n minutos antes se realizo una
# validacion contra POP3 exitosa.
#-----------------------------------------------------------------------------------------
write_to_pop3() {
                sleep 2
                echo "USER ${KHMAIL_POP3_USER}"

                sleep 2
                echo "PASS ${KHMAIL_POP3_PASS}"

                sleep 2
                echo "QUIT"
}




#
#
#
#
#-----------------------------------------------------------------------------------------
write_to_smtp() {
                 sleep ${KHMAIL_SLEEP}
                 echo "EHLO ${KHMAIL_HELO_SERVER}"
                 sleep ${KHMAIL_SLEEP}

		 if (test ${KHMAIL_AUTH_METH} == 'SMTP_PLAIN') then
			echo "AUTH PLAIN ${KHMAIL_SMTPPLAIN}"
		 	sleep ${KHMAIL_SLEEP}
		 fi

		 if (test ${KHMAIL_AUTH_METH} == 'SMTP_LOGIN') then
			echo "AUTH LOGIN"
			sleep ${KHMAIL_SLEEP}
			echo "${KHMAIL_SMTPLOGIN_USER}"
			sleep ${KHMAIL_SLEEP}
			echo "${KHMAIL_SMTPLOGIN_PASS}"
			sleep ${KHMAIL_SLEEP}
		 fi
			
                 echo "MAIL FROM:<${KHMAIL_FROM}>"
                 sleep ${KHMAIL_SLEEP}
                 for i in `echo ${KHMAIL_TO_LIST}`;do
                 echo "RCPT TO:<${i}>"
                 sleep ${KHMAIL_SLEEP}
                 done
                 sleep ${KHMAIL_SLEEP}
                 echo "DATA"

                 sleep ${KHMAIL_SLEEP}
                 echo "Subject: ${KHMAIL_SUBJECT}"
		 sleep ${KHMAIL_SLEEP}
		 echo "From: <${KHMAIL_FROM}>"
                 sleep ${KHMAIL_SLEEP}

                 printf "\n"
                 printf "\n"

                 sleep ${KHMAIL_SLEEP}
                 cat ${KHMAIL_BODY}

                 sleep ${KHMAIL_SLEEP}
                 echo ".\n"
                 echo .
                 echo .

                 sleep ${KHMAIL_SLEEP}
                 echo "quit"
                 echo "quit"
}


#
#
#
#
#-------------------------------------------------------------------------------------------
kh_send_mail() {

echo "-------------------------------------------------------------"
echo "\n"

echo "AUTH METHOD .......... $KHMAIL_AUTH_METH"
echo "POP3 SERVER .......... $KHMAIL_POP3_PORT "
echo "POP3 PORT   .......... $KHMAIL_POP3_SERVER "
echo "POP3 USER   .......... $KHMAIL_POP3_USER"
echo "POP3 PASS   .......... $KHMAIL_POP3_PASS"
echo "SMTP SERVER .......... $KHMAIL_SMTP_SERVER "
echo "SMTP PORT   .......... $KHMAIL_SMTP_PORT  "
echo "HELO SERVER .......... $KHMAIL_HELO_SERVER "
echo "FROM        .......... $KHMAIL_FROM       "
echo "TO LIST     .......... $KHMAIL_TO_LIST     "
echo "SUBJECT     .......... $KHMAIL_SUBJECT      "
echo "BODY        .......... $KHMAIL_BODY         "
echo "SLEEP       .......... $KHMAIL_SLEEP "

if (test ${KHMAIL_AUTH_METH} == 'POP3') then
        write_to_pop3 | telnet ${KHMAIL_POP3_SERVER} ${KHMAIL_POP3_PORT}
fi

write_to_smtp | telnet ${KHMAIL_SMTP_SERVER} ${KHMAIL_SMTP_PORT}

}



kh_send_mail2() {

mutt -s "$KHMAIL_SUBJECT" $KHMAIL_TO_LIST < $KHMAIL_BODY

}
