<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Storage : gestion des volumes disques et partions (montage, démontage, formatage)
- les methodes marquée d'une "*" sont en supplément par rapport à la documentation orginelle.

attention : manipuler ces methodes présente un fort risque de perte de données. A utiliser a vos risques
et périles.


- storage.list (:storage-disk-type) : Liste tous les périphériques de stockage présent sur le NAS avec leurs partitions. 
- storage.mount : 
- storage.umount


* storage.disk_advanced_informations_get
- storage.disk_disable
- storage.disk_format_internal
- storage.disk_get
* storage.format_simple
* storage.partition_fsck
* storage.partition_get
* storage.partition_simple
- storage.disable


types :


storage-disk-type : Périphérique de stockage (disque dur)
- disk_id:int : identifiant du disque dur, nécessaire pour les opérations ciblant un périphérique en particulier
- state
	- error 	Erreur sur le périphérique.
	- disabled 	Périphérique non utilisé.
	- enabled 	Périphérique en cours d'utilisation.
- type

	disk_bus 	Type du périphérique

    total_bytes

	entier 	Taille du disque en octets.

    partitions

	[ partition ] 	Partition d'un disque dur

    connector

	int 	Numéro du connecteur USB/eSATA sur lequel le disque est branché


- script JS : https://github.com/mqu/mafreebox/blob/master/doc/js/nas_storage.js

*/

class Storage {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}
	public function _list(){
		return $this->fb->exec('storage.list');
	}

	/* 
		disk_advanced_informations_get($id) : retourne des informations détaillées concernant un disque,
		- le disque principal est le disque 0,
		- détail des informations retournées :
			Array 
				[temperature_valid] => 1
				[temperature] => int
				[idle_duration] => int (seconds)
				[ata_pm_state] => 255
				[idle] => bool
				[spinning] => int (bool)
				[active_duration] => int
		- les durées sont en secondes.
	*/

	public function disk_advanced_informations_get($id){
		return $this->fb->exec('storage.disk_advanced_informations_get', $id);
	}

	# c'est l'attribut 'disk_id' qui doit être passé à ces méthodes.
	public function mount($id){
		return $this->fb->exec('storage.mount', $id);
	}
	public function umount($id){
		return $this->fb->exec('storage.umount', $id);
	}
	
	public function disable($id){
		return $this->fb->exec('storage.disable', $id);
	}
	
	public function partition_fsck($id){
		return $this->fb->exec('storage.partition_fsck', $id);
	}
}

/*

ci-dessous, un print_r de $freebox->storage->_list();
 - le disque dur est un Seagate ST9250311CS - 250 Go - SATA-300
 - la partition racine fait 249Go, dont 126Go libresn
 - 10 points de montages sont visibles : on peut apprécier le nom de la partition 8 : "public/goinfre",
 - les points de montages sont réalisés avec un "bind",
 - pas de FSCK réalisé sur ce disque : "[fsck_result] => no_run_yet"
 - 

Array
(
    [0] => Array
        (
            [drive_ident] => Array
                (
                    [smart_supported] => 1
                    [rotation_rate] => 5400
                    [model] => ST9250311CS
                    [smart_enabled] => 1
                    [snumber] => 6VCYBJBL
                    [temp_supported] => 1
                    [firmware] => SC16
                )

            [type] => internal
            [total_bytes] => 250059350016
            [connector] => 0
            [table_type] => msdos
            [state_data] => Array
                (
                    [idle] => 0
                )

            [state] => enabled
            [internal_bluray] => 
            [partitions] => Array
                (
                    [0] => Array
                        (
                            [dev_block_count] => 486328125
                            [dev_block_size] => 512
                            [label] => Disque dur
                            [root_free_bytes] => Array
                                (
                                    [str] => 126,20 GBytes
                                    [val] => 126205292544
                                )

                            [bdev_major] => 8
                            [phys_block_size] => 512
                            [used_bytes] => 118886203392
                            [dev_total_bytes] => Array
                                (
                                    [str] => 249,00 GBytes
                                    [val] => 249000000000
                                )

                            [bdev_minor] => 2
                            [fsck_result] => no_run_yet
                            [free_bytes] => 113755295744
                            [bind_places] => Array
                                (
                                    [0] => Array
                                        (
                                            [source] => /
                                            [target] => /mnt/disks/by-label/internal-disk
                                        )

                                    [1] => Array
                                        (
                                            [source] => /private/transmission
                                            [target] => /var/lib/chroots/transmission/appdata/transmission
                                        )

                                    [2] => Array
                                        (
                                            [source] => /private/apps/fbxlpd/spool
                                            [target] => /var/lib/chroots/smb/tmp/fbxlpd_spool
                                        )

                                    [3] => Array
                                        (
                                            [source] => /private/apps/fuppes
                                            [target] => /var/lib/chroots/fuppes/appdata/fuppes
                                        )

                                    [4] => Array
                                        (
                                            [source] => /private/apps/fbxdlmd
                                            [target] => /var/lib/chroots/fbxdlmd/appdata/fbxdlmd
                                        )

                                    [5] => Array
                                        (
                                            [source] => /private/apps/users
                                            [target] => /var/lib/chroots/fbxdlmd/appdata/users
                                        )

                                    [6] => Array
                                        (
                                            [source] => /private/freeboxhd/common/freestore_dl
                                            [target] => /var/lib/chroots/fbxdlmd/appdata/freestore_dl
                                        )

                                    [7] => Array
                                        (
                                            [source] => /private/apps/users
                                            [target] => /var/lib/chroots/fcgi-kahlua/appdata/users
                                        )

                                    [8] => Array
                                        (
                                            [source] => public/goinfre
                                            [target] => /media/Disque dur
                                        )

                                    [9] => Array
                                        (
                                            [source] => private/freeboxhd
                                            [target] => /exports/freeboxhd
                                        )

                                )

                            [fstype] => ext4
                            [partition_id] => 2
                            [total_bytes] => 245091495936
                            [state] => mounted
                            [disk_id] => 0
                        )

                )

            [persist_physpath] => plat-sata_mv.0-scsi-0:0:0:0
            [disk_id] => 0
            [has_media] => 1
        )

)


2Go usb flash drive :

    [1] => Array
        (
            [drive_ident] => Array
                (
                    [smart_supported] => 
                    [rotation_rate] => 0
                    [model] => 
                    [smart_enabled] => 
                    [snumber] => 
                    [temp_supported] => 
                    [firmware] => 
                )

            [type] => usb
            [total_bytes] => 2056257536
            [connector] => 0
            [table_type] => msdos
            [state_data] => Array
                (
                    [idle] => 0
                )

            [state] => enabled
            [internal_bluray] => 
            [partitions] => Array
                (
                    [0] => Array
                        (
                            [dev_block_count] => 4016065
                            [dev_block_size] => 512
                            [label] => ___________
                            [root_free_bytes] => Array
                                (
                                    [str] => 1,25 GBytes
                                    [val] => 1252409344
                                )

                            [bdev_major] => 8
                            [phys_block_size] => 512
                            [used_bytes] => 799784960
                            [dev_total_bytes] => Array
                                (
                                    [str] => 2,05 GBytes
                                    [val] => 2056225280
                                )

                            [bdev_minor] => 17
                            [fsck_result] => no_run_yet
                            [free_bytes] => 1252409344
                            [bind_places] => Array
                                (
                                    [0] => Array
                                        (
                                            [source] => /
                                            [target] => /mnt/disks/by-label/___________
                                        )

                                    [1] => Array
                                        (
                                            [source] => /
                                            [target] => /media/___________
                                        )

                                )

                            [fstype] => vfat
                            [partition_id] => 1001
                            [total_bytes] => 2052194304
                            [state] => mounted
                            [disk_id] => 1000
                        )

                )

            [persist_physpath] => plat-orion-ehci.0-usb-0:1.2:1.0-scsi-0:0:0:0
            [disk_id] => 1000
            [has_media] => 1
        )

)

*/

?>
