Mafreebox
=========

mafreebox - interface d'administration de la Freebox via requetes JSON (php, ruby).

Mafreebox est une interface de programmation (API) qui permet d'accéder aux fonctions d'administration de la Freebox Révolution (V6).
L'API est actuellement disponible en langage PHP. Prochainement, sera développé une API Ruby.

Cette API est organisée en classe de façon modulaire et couvre (couvrira) les aspects suivants :

Mafreebox : couvre les aspects :
- login,
- exécution des requetes JSON,

Account : account basic http authentication
    account.unknown

Fs : Systeme de fichiers : Fonctions permettant de lister et de gérer les fichiers du NAS.
- fs.list
- fs.get
- fs.operation_progress
- fs.operation_list
- fs.abort
- fs.set_password
- fs.move
- fs.copy
- fs.remove
- fs.unpack
- fs.mkdir

Fw : Firewall : Fonctions permettant d'interagir avec le firewall.
- fw.wan_redirs_get
- fw.wan_range_redirs_get
- fw.wan_redir_del
- fw.wan_range_redir_del
- fw.wan_redir_add
- fw.wan_range_redir_add
- fw.dmz_get
- fw.dmz_set
- fw.lfilter_config_get
- fw.lfilter_config_set
- fw.lfilters_get
- fw.lfilter_add
- fw.lfilter_del

Igd : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
- igd.config_get
- igd.config_set
- igd.redirs_ge
- igd.redir_del

IPv6 : Fonctions permettant de configurer IPv6
- ipv6.config_get
- ipv6.config_set

Lan : Fonctions permettant de configurer le réseau LAN.
- lan.ip_address_get
- lan.ip_address_set

Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
- lcd.brightness_get
- lcd.brightness_set

Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage windows de la freebox.
- share.get_config
- share.set_config

Storage : Systeme de stockage : Gestion du disque dur interne et des disques externe connectés au NAS.
- storage.list
- storage.disk_get
- storage.disk_format_internal
- storage.disk_disable
- storage.mount
- storage.umount
- storage.disable

User : Utilisateurs : Permet de modifier les paramétres utilisateur du boîtier NAS.
- user.password_reset
- user.password_set
- user.password_check_quality

WiFi : Fonctions permettant de paramétrer le rÃ©seau sans-fil.
- wifi.status_get
- wifi.config_get
- wifi.ap_params_set
- wifi.bss_params_set
- wifi.mac_filter_add
- wifi.mac_filter_del
- wifi.stations_get

Exemples d'utilisation :

<?php

error_reporting(E_ALL);

require_once('lib/Mafreebox.php');

$freebox = new Mafreebox('http://mafreebox.freebox.fr', 'freebox', 'mon.mdp');

# Listons le contenu du disque dur interne de la Freebox.
$contenu = $freebox->exec( 'fs.list', array('/Disque dur') );

# ajouter un téléchargement
$url = '';
$file = '';
$freebox->download()->http_add($file, $url));

# rebooter la freebox
$freebox->system()->reboot();

?>

