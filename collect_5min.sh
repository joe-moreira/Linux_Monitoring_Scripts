. /home/jmoreira/operaciones/scripts/khlnxenv.sh   /home/jmoreira/operaciones/conf/soportetestunx.conf
FLAG=/tmp/collectlnx_5min.lck

FECHA=`date +"%Y-%m-%d %H:%M:%S"`
INDID='-'
OBJETO=$0
VALOR=-1

test -e $FLAG
# si existe, salimos y no ejecutamos porque una ejecucion anterior ejecuto inconclusa
if [ $? -eq 0  ]; then
    echo "No se ejecuto $0 por flag existente: ${FLAG}"
    echo "${FECHA}   ${HOST}   ${INDID}    ${OBJETO}    ${VALOR} No se ejecuto $0 por flag existente: ${FLAG} " >> ${CONSOLA}.$$.tmp
    cat ${CONSOLA}.$$.tmp >> ${CONSOLA}
    KHMAIL_SUBJECT="${KHMAIL_SUBJECT_ALERT_HEAD};collectlnx_5min.sh;${FECHA};${FECHA};ERROR"
    KHMAIL_BODY=${CONSOLA}.$$.tmp
    kh_send_mail
    rm -f ${CONSOLA}.$$.tmp 2>/dev/null

    exit -1
fi

# enciendo flag
touch $FLAG

# fs con mas de N MB usados (110)
ctrlfsspaceused / 11000
ctrlfsspaceused /u02 150000
ctrlfsspaceused /compartido 80000

# fs con mas de N % usados (111)
ctrlfspctused / 80
ctrlfspctused /u02 94
ctrlfspctused /compartido 80

# control de disponibilidad (502)
ctrldisplnx

# control de carga de CPU (401)
ctrlcpuload 70

# control de procesos en cola a la espera de CPU (402)
ctrlrunqueueload 1

# control de swap-in (340)
ctrlswapinload 0

# control swap disponible (341)
ctrlswapdisponible 30

# control de I/O wait (403)
ctrlcpuiowait 30 

# control carga promedio (404)
ctrlloadaverage 0  

# control carga memoria (342)
ctrlmemuse  80

# cierro flag
rm -f $FLAG
