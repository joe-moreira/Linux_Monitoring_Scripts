KHCMRVERSION=2.0.1

if [ $# != 1 ]; then
   echo "Uso : . khpgenv <arch-conf>"
   echo "KH-CMR Version : ${KHCMRVERSION}"
   return 1
else
   . $1
   if [ $? != 0 ]; then
      echo "Error ejecutando archivos de configuracion"
      echo "Entorno no quedo configurado correctamente"
      return 1
   fi
   . ${KHSCRIPTSDIR}/khutils.sh
   if [ $? != 0 ]; then
      echo "Error generando entorno con funciones de mail"
      echo "Entorno no quedo configurado correctamente"
      return 1
   fi
fi

### Funciones

khcmrlnxfuncs(){
echo "KH-CMR Version : ${KHCMRVERSION}"
stat -c "%s %y" ${KHSCRIPTSDIR}/khlnxenv.sh
echo " "
echo "Funciones"
echo "---------"
cat ${KHSCRIPTSDIR}/khlnxenv.sh | grep -i '(){'|grep -v grep|cut -d'(' -f1 | sort
echo " "
echo "Aliases"
echo "-------"
#cat ${KHSCRIPTSDIR}/khlnxenv.sh | grep "^alias" | awk -F= '{ print  $1}'| awk  '{ print  $2}' | sort echo " "
cat ${KHSCRIPTSDIR}/khlnxenv.sh | grep "^alias" | awk -F= '{ print  $1}'| awk  '{ print  $2}' | sort 

}

#######################################################################################

# muestra espacio ocupado por un fs en MB
fsspaceused(){

  FS=$1

  if [ "$FS" = "" ]; then
     echo "Uso : fsspaceused <fs>"
     return
  fi

  test -d $FS
  if [ $? -ne 0 ]; then
     echo "ERROR : filesystem $FS no existe"
     return 1
  else
     df  -P -m $FS| grep -v "Filesystem"|awk  '{ print  $3}'
     return $?
  fi
}

# muestra espacio ocupado por un fs en %
fspctused(){
  FS=$1

  if [ "$FS" = "" ]; then
     echo "Uso : fsspaceused <fs>"
     return
  fi

  test -d $FS
  if [ $? -ne 0 ]; then
     echo "ERROR : filesystem $FS no existe"
     return 1
  else
     df  -P -m $FS| grep -v "Filesystem"|awk  '{ print  $5}'
     return $?
  fi
}

# Disk Usage ordenado por size
# Uso: 	duf /tmp/*  	Muestra los archivos y subdirectorios de /tmp con sus tamanios ordenado
#	duf /tmp	Muestra el tamanio de /tmp

duf(){
du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ $size -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size=$((size/1024)); done; done
}




#########################################################
# Funciones de Control
#########################################################


# Control de tamanio swap disponible en % 
# Parametros : umbral minimo en %. Si el area de paginado disponible es menor que el umbral especificado, entonces notificara la alerta.
ctrlswapdisponible(){

  N=$1

  if [ "$N" = "" ]; then
     echo "Uso : ctrlswapdisponible <% min de paginado disponible>"
     return
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=341
  OBJETO="Swap disponible"

#calculo tamaño swap disponible
  VALOR=`lsps -a | grep -v "Page Space" |  awk '{print $5}'`
  let "VALOR = 100 - $VALOR"

  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

   if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -lt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID}  ${OBJETO}   ${VALOR} Valor de SWAP es menor que el limite especificado ${N} %" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlswapdisponible;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}


# Control de swap in. Un valor no-cero significa que la memoria fisica es insuficiente. 
# Parametros : cant swap in maximo antes de notificar la alerta (opcional)
ctrlswapinload(){
 
  N=$1

  if [ "$N" = "" ]; then
#     echo "Uso : ctrlswapinload <max permitido de swap in>"
#     return
    N=0
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=340
  OBJETO="Swap in"
  VALOR=`vmstat 2 5 | tail -1 | awk '{print $6}'`
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

  if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID}  ${OBJETO}  ${VALOR} Se produjo un exceso de swap-in mayor al limite : $N. Se requiere mas memoria fisica." > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlswapinload;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}


# Control de uso total de Memoria en %   
# Parametros : umbral maximo permitido en % antes de notificar la alerta.
ctrlmemuse(){

  N=$1

  if [ "$N" = "" ]; then
     echo "Uso : ctrlmemuse <limite maximo en %>"
     return
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=342
  OBJETO="Uso Memoria"
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

  MEMTOTAL=`lsattr -El sys0 -a realmem | awk '{ print $2 }'`
  MEMTOTAL=`expr $MEMTOTAL / 1024`
  MEMUSO=`svmon -G | head -2 | tail -1 | awk '{ print $3 }'`
  MEMUSO=`expr $MEMUSO / 256`
  VALOR=$(($MEMUSO * 100 / $MEMTOTAL))
 
 if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID} ${OBJETO}  ${VALOR} Valor memoria en uso es mayor que el limite especificado ${N} %" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlmemuse;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}


# Control de Carga total media hace 1 minuto 
# Parametros : umbral maximo permitido para el uptime
ctrlloadaverage(){

  N=$1

  if [ "$N" = "" ]; then
     echo "Uso : ctrlloadaverage <limite maximo permitido>"
     return
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=404
  OBJETO="Load Average"
  VALOR=`uptime | cut -d' ' -f17 | cut -c1`
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

 if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID} ${OBJETO}  ${VALOR} El valor de carga promedio del servidor es mayor que ${N}." > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlloadaverage;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}


# Control de I/O Wait del CPU en % 
# Parametros : umbral maximo permitido de IO Wait en %
ctrlcpuiowait(){

  N=$1

  if [ "$N" = "" ]; then
     echo "Uso : ctrlcpuiowait <limite maximo permitido en %>"
     return
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=403
  VALOR=`vmstat 2 5 | tail -1 | awk '{print $17}'`
  OBJETO="CPU I/O wait"
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`
	

 if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID} ${OBJETO}  ${VALOR} Valor de I/O de CPU es mayor que el limite especificado ${N} %" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlcpuiowait;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}


# Control de cola de procesos a la espera de CPU. Debe ser menor al numero total de Cores
# Parametro : numero maximo de procesos permitidos en cola de espera antes de notificar la alerta (opcional)
ctrlrunqueueload(){

  N=$1
  # obtengo cantidad de cores de CPU del equipo
  T=`prtconf | grep -i processor | grep "Number Of Processors" | awk '{print $4}'`
  if [ "$N" = "" ]; then
#     echo "Uso : ctrlrunqueueload <cpu> <limite en valor absoluto>"
#     return
     # Si no se le pasa parametro, por defecto uso la cantidad de cores que tiene el equipo.
     N=$T
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=402
  OBJETO="Run Queue CPU "
  VALOR=`vmstat 2 5 | tail -1 |awk '{print $1}'`
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

 if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID} ${OBJETO}  ${VALOR} Hay mas procesos en cola de espera de CPU que $N (numero total de Cores = $T). Servidor requiere mas CPU" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlrunqueueload;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
fi
}

# Control de la carga de CPU 
# Parametros : umbral maximo en %
ctrlcpuload(){

  N=$1
  if [ "$N" = "" ]; then
     echo "Uso : ctrlcpuload <limite maximo en %>"
     return
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=401
  OBJETO="Carga total CPU"
  TMPAUX=${TMPDIR}/vmstat_cpuload.tmp.$$

  vmstat 2 5 | grep -v "r" | tail -1 > ${TMPAUX}
  U=`awk -F' ' '{ print $14 }' $TMPAUX`
  S=`awk -F' ' '{ print $15 }' $TMPAUX`
  VALOR=$(($U + $S))

  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

  if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID}  ${OBJETO}  ${VALOR} Consumo total de CPU es mayor que el limite especificado ${N} %" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlcpuload;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
        fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
    fi
  fi
  rm -f ${TMPAUX}
}

# Control de tamaño fs en MB
# Parametros : nombre del fs y umbral maximo en MB
ctrlfsspaceused(){
  FS=$1
  N=$2

  if [ "$N" = "" ]; then
     echo "Uso : ctrlfsspaceused <fs> <limite en MB>"
     return 1
  fi

  test -d $FS
  if [ $? -ne 0 ]; then
     echo "ERROR : filesystem $FS no existe"
     return 1
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=110
  OBJETO=$FS
  VALOR=`fsspaceused $FS`
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`
  # si VALOR es nulo, es porque el awk no trajo nada y seguramente la base no sea valida
  if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID}    ${OBJETO}    ${VALOR} Espacio ocupado por fs $FS es mayor que el limite especificado ${N} MB" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
#            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD}:ctrlfsspaceused:110"
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlfsspaceused;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
  fi
}

# Control de tamaño fs en %
# Parametros : nombre del fs y umbral maximo en %
ctrlfspctused(){
  FS=$1
  N=$2

  if [ "$N" = "" ]; then
     echo "Uso : ctrlfspctused <fs> <limite en %>"
     return 1
  fi

  test -d $FS
  if [ $? -ne 0 ]; then
     echo "ERROR : filesystem $FS no existe"
     return 1
  fi

  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=111
  OBJETO=$FS
  VALOR=`fspctused $FS | awk -F"%" '{ print  $1}'`
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`

  # si VALOR es nulo, es porque el awk no trajo nada y seguramente la base no sea valida
  if [ "$VALOR" != "" ]; then
     echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
     if [ $VALOR -gt $N ]; then
        echo "${FECHA}   ${HOST}   ${INDID}    ${OBJETO}    ${VALOR} Espacio ocupado por fs $FS es mayor que el limite especificado ${N} %" > ${CONSOLA}.$$.tmp
         if [ "$KHALERT" = "C" ] || [ "$KHALERT" = "B" ]; then
            cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
         fi
         if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
#            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD}:ctrlfspctused:111"
            KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrlfspctused;${FECHA};${FECHAFIN};ERROR"
            KHMAIL_BODY=${CONSOLA}.$$.tmp
            kh_send_mail
         fi
         rm -f ${CONSOLA}.$$.tmp 2>/dev/null
     fi
  fi
}

# Control de disponibilidad. Manda mail, si llega al plugin es por que el servidor esta arriba, si no llega el plugin detectara que algo paso.
# Igual registra en indicatorsvalues, asique si registra bien en indicatosvalues y el plugin no recibio el mail, es que hubo problema de red o mail, pero el servidor estaba arriba.
ctrldisplnx(){
  FECHA=`date +"%Y-%m-%d %H:%M:%S"`
  INDID=502
  OBJETO="-"
  VALOR=0
  echo ${FECHA}"|"${HOST}"|"${INDID}"|"${OBJETO}"|"${VALOR} >> ${INDICADORES}
  FECHAFIN=`date +"%Y-%m-%d %H:%M:%S"`
  echo "${FECHA}   ${HOST}   ${INDID}    ${OBJETO}    ${VALOR} Servidor disponible" > ${CONSOLA}.$$.tmp
  if [ "$KHALERT" = "M" ] || [ "$KHALERT" = "B" ]; then
     KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};ctrldisplnx;${FECHA};${FECHAFIN};OK"
     KHMAIL_BODY=${CONSOLA}.$$.tmp
     kh_send_mail
  fi
  rm -f ${CONSOLA}.$$.tmp 2>/dev/null
}

