#!/bin/bash


#Actualizamos los repositorios
apt-get update

#Instalamos el bind9
apt-get install -y bind9

#Copiamos el archivo de configuracion default como copia de seguridad
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.V2

#Con cat leemos el archivo que con el parametro EOF (End of file) podemos escribir
#toda la configuracion necesaria.
cat <<EOF > /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";

	 forwarders {
		8.8.8.8;
		1.1.1.1;
	 };

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation auto;

	listen-on-v6 { any; };
};
#Finalizamos el EOF para que no siga leyendo.
EOF
echo " "
cp /etc/bind/named.conf.local /etc/bind/named.conf.localV2
#Aqui le pedimos al usuario que introduzca el nombre de su dominio para la primera zona primaria
read -p "Introduce el nombre de dominio: " dominio
cat <<EOF > /etc/bind/named.conf.local
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "$dominio" {
	type master;
	file "/etc/bind/db.$dominio";
};
EOF

echo "  "
#Copiamos la configuracion local de la base de datos del dns y le ponemos
#el nombre del dominio
cp /etc/bind/db.local /etc/bind/db.$dominio
#Le pedimos la ip del servidor DNS
read -p "Ingresa la direccion ip del servidor DNS: " ip_dns
#Obtenemos el nombre del hostname automaticamente.
ns1=$(hostname)


cat <<EOF > /etc/bind/db.$dominio

\$TTL	604800
@	IN	SOA	$ns1.$dominio. root.$dominio. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$ns1.$dominio.
$ns1	IN	A	$ip_dns

EOF
#Reiniciamos el servicio
systemctl restart bind9
echo "Configuracion completada para $dominio"
