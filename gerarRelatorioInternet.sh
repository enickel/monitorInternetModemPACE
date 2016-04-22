#! /bin/bash

# Este foi desenvolvido por David Alain

# ==== Variáveis ====
globalIP=""

dslStatus=""
pppStatus=""

currentSpeedDown=""
currentSpeedUp=""
maxSpeedDown=""
maxSpeedUp=""
snrUp=""
snrDown=""
dateTime=""

delayTime=8

csvLine=""

workingPath="relatorioInternetGVT/"
csvFileOut="estatisticas.csv"
csvHeaderOut="cabecalhoEstatisticas.csv"

# ===================

printHeader(){
	# Gera o arquivo de cabeçalho
	echo "dateTime,dslStatus,pppStatus,globalIP,maxSpeedDown[Kbps],maxSpeedUp[Kbps],currentSpeedDown[Kbps],currentSpeedUp[Kbps],snrDown[dB],snrUp[dB],outputPowerDown[dBm],outputPowerUp[dBm]"
}

init(){
	# Entra no diretório de trabalho
	cd ~
	mkdir -p $workingPath
	cd $workingPath
	echo "Diretório atual: $(pwd)"

	printHeader > $csvHeaderOut
}

gerarRelatorio(){


	# Remove o arquivo existente para baixar um novo
	rm -f status.txt

	# Acessa o modem via SSH e executa o comando remoto salvando a saída localmente no PC
	sshpass -p "toor" ssh root@192.168.25.1 '( /home/diag/usr/bin/xdslinfo && /home/diag/bin/ifconfig ppp1 )' > status.txt

	# Pega o horário atual
	dateTime=$(date)
	#echo "dateTime=$dateTime"

	# Pega o status do DSL
	dslStatus=$(cat status.txt | grep "line state" | awk '{print $4}')
	#echo "dslStatus=$dslStatus"

	# Se já foi criada a conexão ppp1 e já está conectado
	cat status.txt | grep "ppp1" > /dev/null
	v1=$?
	cat status.txt | tail -n10 | grep "UP" > /dev/null
	v2=$?

	if [ $v1 -eq 0 ] && [ $v2 -eq 0 ] ; then

		# Pega o status do PPP
		pppStatus="UP"
		#echo "pppStatus=$pppStatus"

		# Pega o valor do IP válido
		globalIP=$(cat status.txt | tail -n10 | grep "addr:" | awk '{print $2}' | tr ":" " " | awk '{print $2}')
		#echo "globalIP=$globalIP"

		# Se estava com internet, então não precisa monitorar com muita frequência, uma amostra a cada 10 segundos é suficiente. Leva-se 2 segundos para cada medição.
		delayTime=8
	else

		# Pega o status do PPP
		pppStatus="DOWN"
		#echo "pppStatus=$pppStatus"

		# Pega o valor do IP válido
		globalIP=""
		#echo "globalIP=$globalIP" 

		# Estava sem internet, então precisa monitorar com muita frequência, uma amostra a cada 5 segundos é o recomendado. Leva-se 2 segundos para cada medição.
		delayTime=3
	fi

	# Pega os valores (Max Speed)
	maxSpeedDown=$(cat status.txt | grep "down max rate" | awk '{print $6}')
	#echo "maxSpeedDown=$maxSpeedDown"

	maxSpeedUp=$(cat status.txt | grep "up max rate" | awk '{print $6}')
	#echo "maxSpeedUp=$maxSpeedUp"

	# Pega os valores (Current Speed)
	currentSpeedDown=$(cat status.txt | grep "down actual rate" | awk '{print $6}')
	#echo "currentSpeedDown=$currentSpeedDown"

	currentSpeedUp=$(cat status.txt | grep "up actual rate" | awk '{print $6}')
	#echo "currentSpeedUp=$currentSpeedUp"

	# Pega os valores (SNR)
	snrDown=$(cat status.txt | grep "down noise margin" | awk '{print $6}')
	#echo "snrDown=$snrDown"

	snrUp=$(cat status.txt | grep "up noise margin" | awk '{print $6}')
	#echo "snrUp=$snrUp"

	# Pega os valores (Output Power)
	outputPowerDown=$(cat status.txt | grep "down output power" | awk '{print $6}')
	#echo "outputPowerDown=$outputPowerDown"

	outputPowerUp=$(cat status.txt | grep "up output power" | awk '{print $6}')
	#echo "outputPowerUp=$outputPowerUp"


	csvLine="$dateTime,$dslStatus,$pppStatus,$globalIP,$maxSpeedDown,$maxSpeedUp,$currentSpeedDown,$currentSpeedUp,$snrDown,$snrUp,$outputPowerDown,$outputPowerUp"
	printHeader
	echo $csvLine

	echo $csvLine >> $csvFileOut
}

# ========== Código principal (main) ===============


init

while [ 1 ] ; do

	echo "===== Rodando... ========================================="
	gerarRelatorio

	echo "===== Esperando horário da próxima execução ($delayTime seg) ====="

	sleep $delayTime
done



