Mafreebox
=========

**mafreebox - interface d'administration de la Freebox via requetes JSON (php, ruby).**

Mafreebox est une interface de programmation (API) qui permet d'accéder aux fonctions d'administration de la Freebox Révolution (V6).
L'API est actuellement disponible en langage PHP. Prochainement, sera développé une API Ruby.

Cette API est organisée en classe de façon modulaire et couvre (couvrira) les aspects suivants :

**Mafreebox** : couvre les aspects :
- login,
- exécution des requetes JSON,
- interface d'accès aux différents services organisés sous forme de modules.

**Modules**
- **Account** : account basic http authentication account.unknown
- **DHCP** : Gestion du serveur DHCP,
- **Download** : Gestionnaire de téléchargement ftp/http/torrent.
- **Ftp** : gestion du serveur FTP,
- **Fs** : Systeme de fichiers : Fonctions permettant de lister et de gérer les fichiers du NAS.
- **Fw** : Firewall : Fonctions permettant d'interagir avec le firewall.
- **Igd** : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
- **IPv6** : Fonctions permettant de configurer IPv6
- **Lan** : Fonctions permettant de configurer le réseau LAN.
- **Lcd** : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
- **Phone** : Gestion de la ligne téléphonique analogique et de la base DECT.
- **Share** : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage Windows de la Freebox.
- **Storage** : Systeme de stockage : Gestion du disque dur interne et des disques externe connectés au NAS.
- **System** : fonctions système de la Freebox,
- **User** : Utilisateurs : Permet de modifier les paramétres utilisateur du boîtier NAS.
- **WiFi** : Fonctions permettant de paramétrer le réseau sans-fil.


**Exemples d'utilisation** :
```php
<?php

error_reporting(E_ALL);

require_once('lib/Mafreebox.php');

$freebox = new Mafreebox('http://mafreebox.freebox.fr', 'freebox', 'mon.mdp');

# Listons le contenu du disque dur interne de la Freebox.
$contenu = $freebox->exec( 'fs.list', array('/Disque dur') );

# ajouter un téléchargement
$url = 'http://www..../mon-fichier.txt';
$file = 'mon-ficher.txt';
$freebox->download->http_add($file, $url));

# rebooter la freebox
$freebox->system->reboot();

?>
```

**dépendances liées à l'environnement PHP** :
```bash
# installation des dépendances php5 + curl
# sudo apt-get install php5-cli php5-curl
# php -q test-mafreebox.php
```

**mise en oeuvre** :

```bash
# mkdir $HOME/tmp && cd $HOME/tmp
# git clone https://github.com/mqu/mafreebox
# php -q test-mafreebox.php
```

**Documentation**

Vous trouverez toute la documentation sur le Wiki github : <https://github.com/mqu/mafreebox/wiki>
