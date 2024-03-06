#!/bin/bash
# Testato em Kali 2019 e Debian 9 e 10
# Instalação do LibreOffice direatamente do Site, sempre que
#executado, atualiza para última versão.
# Autor: Hugo Souza
#
clear
if [[ `id -u` != "0" ]]
then
	echo "Você precisa de privilégios de root para continuar."
	exit
else
echo "Bem vindo ao instalador do Libreoffice, aguarde enquanto detectamos se sua versão está atualizada..."
SOFTWARES="curl mkdir wget tar dpkg cut"
installSoftwares () {
    for software in ${SOFTWARES}
    do
        SOFTWARE=`command -v ${software}`
        if [[ -f ${SOFTWARE} ]];
        then
            # Export the full path of the softwares/packages to variables:
            # e.g. PING=/bin/ping
            export ${software^^}=${SOFTWARE}
        else
        	MISSING_SOFTWARE+=("${software} ")
        fi
    done
	if [[ ${#MISSING_SOFTWARE[@]} != 0 ]];
	then
		echo -e "\e[1m\e[31mWARNNING [*]\e[0m Existem dependências a serem instaladas (There are dependencies to be installed): \e[33m(${MISSING_SOFTWARE[@]})\e[0m"
    echo -ne "Deseja continuar? (Do you wish to continue?) [S/n/Y/y Default=N/n] "
		read RESP
		if [[ "${RESP}" == "S" ]] || [[ "${RESP}" == "s" ]] || [[ "${RESP}" == "y" ]] || [[ "${RESP}" == "Y" ]]
		then
			#apt update
			apt install -y ${MISSING_SOFTWARE[@]}
			MISSING_SOFTWARE=()
			installSoftwares
		else
			echo -e "Abortando ..."
			exit
		fi
	fi
}

installSoftwares
 # Lista de mirror para download.
 # MIRROR_LIST="http://mirror.pop-sc.rnp.br/mirror/tdf/libreoffice/stable \
 # https://tdf.c3sl.ufpr.br/libreoffice/stable \
 # https://mirror.ufca.edu.br/mirror/tdf/libreoffice/stable" \
 # https://download.documentfoundation.org/libreoffice/stable"

  MIRROR_LIST="https://download.documentfoundation.org/libreoffice/stable"

  # Versão atual instalada
  # Em caso de atualização para versão 6.4, alterar a variável abaixo
  # Current Version instaled.
  SOFFICE=`find /opt /usr /sbin /bin -type f -iname soffice`
  CURRENT_VERSION=`${SOFFICE} --version | ${CUT} -d " " -f 2`

  # New version
  NEW_VERSION=`${CURL} -s  https://www.libreoffice.org/download/download-libreoffice/ | grep -Ei "dl_version_number" | head -1 | sed 's@</span.*$@@' | sed 's@^.*number">@@'`

  # PACKAGE
  PACKAGE="deb"

  # Arquitetura
  ARCH="x86-64"


  # Função para fazer o download dos arquivos
  filesDownload() {
  	# Arquivo principal
  	${WGET} -c ${MIRROR}/${NEW_VERSION}/${PACKAGE}/${ARCH//-/_}/LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}.tar.gz

  	# Arquivo de tradução pt-BR
  	${WGET} -c ${MIRROR}/${NEW_VERSION}/${PACKAGE}/${ARCH//-/_}/LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}_langpack_pt-BR.tar.gz

  	# Arquivo de ajuda pt-BR
  	${WGET} -c ${MIRROR}/${NEW_VERSION}/${PACKAGE}/${ARCH//-/_}/LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}_helppack_pt-BR.tar.gz
  }


  # Função para extrair os arquivos
  filesExtract() {
  	${MKDIR} main
  	cd main
  	tar -xvf ../LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}.tar.gz --strip-components=1
  	cd ..
  	${MKDIR} langpack
  	cd langpack
  	tar -xvf ../LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}_langpack_pt-BR.tar.gz --strip-components=1
  	cd ..
  	${MKDIR} helppack
  	cd helppack
  	tar -xvf ../LibreOffice_${NEW_VERSION}_Linux_${ARCH}_${PACKAGE}_helppack_pt-BR.tar.gz --strip-components=1
  	cd ..
  }


  # Função para instalar os arquivos .deb
  filesInstall() {
  	${DPKG} -i `pwd`/main/DEBS/*.deb
  	${DPKG} -i `pwd`/langpack/DEBS/*.deb
  	${DPKG} -i `pwd`/helppack/DEBS/*.deb

  	# # Associa a variavel SOFFICE a nova localizaco do binario atualizado.
  	# SOFFICE=`find /opt /usr /sbin /bin -type f -iname soffice`

  	# Cria um link simbólico do novo binario soffice
  	ln -fs ${SOFFICE} /usr/local/bin/soffice
  	source /etc/profile
  }

  update() {
  	for MIRROR in $MIRROR_LIST
  	do
  	echo -e "\e[32m===>\e[0m Testando mirror ${MIRROR}"
  	${CURL} --silent --head --fail ${MIRROR}/${NEW_VERSION}/${PACKAGE}/${ARCH//-/_}/ &> /dev/null
  	if [ $? = 0 ]
  	then
  		echo -e "\e[32m====>\e[0m O mirror $MIRROR está on-line e o dowload será feito por ele."
  		if [ -d /tmp/libreoffice_$NEW_VERSION ]
  		then
  			cd /tmp
  			echo "Diretório ja existe, removendo arquivos antigos."
  			rm -rf /tmp/libreoffice*
  			cd libreoffice_${NEW_VERSION}
  			filesDownload
  			filesExtract
  			filesInstall
  			exit
  		else
  			cd /tmp
  			echo -e "\e[32m=====>\e[0m Criando o diretório temporário para salvar os arquivos"
  			${MKDIR} libreoffice_${NEW_VERSION}
  			cd libreoffice_${NEW_VERSION}
  			filesDownload
  			filesExtract
  			filesInstall
  			exit
  		fi
  	else
  		echo -e "\e[31m===>\e[0m O mirror $MIRROR está offline, testando o próximo"
  	fi
  done
  }

  # Verificar atualização
  verifyUpdate() {
  	if [[ "${NEW_VERSION}" > "${CURRENT_VERSION}" ]]
  	then
  		echo "Libreoffice desatualizado."
  		echo -e "\e[31m[*]\e[0m Versão instalada: ${CURRENT_VERSION}"
  		echo -e "\e[32m[*]\e[0m Versão no site: ${NEW_VERSION}"
  		echo -ne "\e[33m[*]\e[0m Versão instalada não está atualizada, deseja continuar? [S/n] "
  		read RESP
  		if [[ "${RESP}" == "S" ]] || [[ "${RESP}" == "s" ]]
  		then
  			apt update
  			apt remove -y --purge libreoffice*
  			update
  		else
  			echo -e "\e[31m[*]\e[0m Abortando ..."
  		fi
  	else
  		echo "Libreoffice atualizado."
  		echo -e "\e[32m[*]\e[0m Versão instalada: ${CURRENT_VERSION}"
  		echo -e "\e[32m[*]\e[0m Versão no site: ${NEW_VERSION}"
  		exit

  	fi
  }
    verifyUpdate
  fi
