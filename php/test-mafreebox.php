<?php

error_reporting(E_ALL);

require_once('lib/Mafreebox.php');

function get_arg($idx=1, $default=false){
	if(isset($_SERVER["argv"][$idx]))
		return $_SERVER["argv"][$idx];
	return $default;
		
}

function file_rotate($file, $count, $dir='var/'){

	$infos = pathinfo($file);
	$files = glob(sprintf('%s%s.%s.*',$dir, $infos['filename'],$infos['extension']));
	# sort($files, SORT_NATURAL);
	natcasesort($files);
	$files = array_reverse($files);

	foreach($files as $i => $f){
		if((count($files) -$i) > $count-1){
			printf("## unlinking file $f \n");
			# unlink($f);
		}
		else {
			$base = basename($f);
			$inf = pathinfo($f);
			$id = $inf['extension'];
			$name = sprintf("%s/%s", $inf['dirname'], $inf['filename']);
			$f1 = sprintf("%s.%s", $name, $id);
			$f2 = sprintf("%s.%s", $name, $id+1);
			# printf("## rename %s -> %s\n", $f1, $f2 );
			if(file_exists($f1)) rename($f1, $f2);
		}
	}
	
	$path = sprintf('%s%s',$dir, $file);
	if(file_exists($path)) rename($path, $path.'.1');
}

# mettre les paramêtres de connexion de préférence dans le fichier de configuration 
# valable surtout quand on contribue au source (dépot GIT par exemple).
#
$config_file = sprintf('%s/.config/mafreebox.cfg', getenv('HOME'));
if(file_exists($config_file)){
	require_once($config_file);
} else
	$config = array(
		'url'      => 'http://mafreebox.freebox.fr/',
		'user'     => 'freebox',
		'password' => '123456' # your password
	);

$freebox = new Mafreebox($config['url'], $config['user'], $config['password']);


/*
	period = {hour|day|week}
	type={rate|snr}
	dir={down|up}

*/

function rrd_daily($freebox){
	$f = 'rrd-rate-day-up.png';   file_rotate("$f", 31); file_put_contents("var/$f", $freebox->rrd_graph($type='rate', $period='day', $dir='up'));
	$f = 'rrd-rate-day-down.png'; file_rotate("$f", 31); file_put_contents("var/$f", $freebox->rrd_graph($type='rate', $period='day', $dir='down'));
	$f = 'rrd-snr-day.png';       file_rotate("$f", 31); file_put_contents("var/$f", $freebox->rrd_graph($type='snr',  $period='day'));
}

function rrd_hourly($freebox){
	# $f = 'rrd-rate-hourly-up.png';   file_rotate("$f", 24); file_put_contents("var/$f", $freebox->rrd_graph($type='rate', $period='hour', $dir='up'));
	$f = 'rrd-rate-hourly-down.png'; file_rotate("$f", 24); file_put_contents("var/$f", $freebox->rrd_graph($type='rate', $period='hour', $dir='down'));
	# $f = 'rrd-snr-hourly.png';       file_rotate("$f", 24); file_put_contents("var/$f", $freebox->rrd_graph($type='snr',  $period='hour'));

	# $f = 'rrd-wan-rate-hourly-up.png';   file_rotate("$f", 24); file_put_contents("var/$f", $freebox->rrd_graph($type='wan-rate', $period='hour', $dir='up'));
	# $f = 'rrd-wan-rate-hourly-down.png'; file_rotate("$f", 24); file_put_contents("var/$f", $freebox->rrd_graph($type='wan-rate', $period='hour', $dir='down'));

}

switch(get_arg(1, 'daily')){


	case 'get-ejs':

	$list = <<<EOF
		tpl/conn_ddns_provider_status.ejs
		tpl/fw_wan_redir.ejs
		tpl/igd_redir.ejs
		tpl/lfilter_entry.ejs
		tpl/nas_storage_disk_advanced_informations.ejs
		tpl/nas_storage_disk.ejs
		tpl/nas_storage_disk_format_config.ejs
		tpl/nas_storage_disk_format_config_simple.ejs
		tpl/nas_storage_disk_format_confirm.ejs
		tpl/nas_storage_disk_format_error.ejs
		tpl/nas_storage_disk_format_progress.ejs
		tpl/nas_storage_disk_format_success.ejs
		tpl/nas_storage_format_confirm.ejs
		tpl/nas_storage_format_error.ejs
		tpl/nas_storage_format_progress.ejs
		tpl/nas_storage_format_success.ejs
		tpl/nas_storage_partition_fsck_config.ejs
		tpl/nas_storage_partition_fsck_error.ejs
		tpl/nas_storage_partition_fsck_progress.ejs
		tpl/nas_storage_partition_fsck_result.ejs
		tpl/nas_storage_partition_fsck_unsupported.ejs
		tpl/net_ethsw_mac_address_table_entry.ejs
		tpl/net_ethsw_port_state.ejs
		tpl/net_ethsw_port_stats_counters.ejs
EOF;
		$list = explode("\n", $list);
		foreach($list as $f){
			$f = trim($f);
			printf("%s\n", $f);
			$content = $freebox->uri_get($f);
			print_r($content);
		}

		break;

	case 'hour': 
	case 'hourly': 
		rrd_hourly($freebox);
		break;

	case 'day': 
	case 'daily': 
		rrd_dayly($freebox);
		break;

	case 'week': 
	case 'weekly': 
		rrd_weekly($freebox);
		break;


	case 'json':
	case 'json-exec':
	case 'exec':
		print_r($freebox->exec('conn.status'));
		break;

	case 'dhcp': 
		print_r($cnf = $freebox->dhcp->config_get());
		# print_r($cnf = $freebox->dhcp->config_set($cnf));
		print_r($freebox->dhcp->status_get());
		print_r($freebox->dhcp->leases_get());
		print_r($freebox->dhcp->sleases_get());
		break;

	case 'system': 
		print_r($freebox->system->uptime_get());
		print_r($freebox->system->mac_address_get());
		print_r($freebox->system->fw_release_get());
		# print_r($freebox->phone->reboot($timeout=60));
		break;

	case 'phone': 
		# print_r($freebox->phone->fxs_ring(true)); sleep (3);
		# var_dump($freebox->phone->fxs_ring(false));
		print_r($freebox->phone->status());
		break;

	case 'ftp': 
		print_r($cnf = $freebox->ftp->get_config());
		# $cnf['enabled'] = 1;
		# $cnf['allow_anonymous'] = 1;
		# $cnf['allow_anonymous_write'] = 1;
		# $cnf['password'] = '123456';
		# $cnf = $freebox->ftp->get_config($cnf);
		break;

	case 'storage': 
		print_r($cnf = $freebox->storage->_list());
		print_r($cnf = $freebox->storage->disk_advanced_informations_get(0));
		# print_r($cnf = $freebox->storage->mount(1001));
		# print_r($cnf = $freebox->storage->partition_fsck(1001));
		# sleep (2) ; print_r($cnf = $freebox->storage->_list());
		# print_r($cnf = $freebox->storage->disable(1000));

		# print_r($cnf = $freebox->storage->disk_get(0));
		# print_r($cnf = $freebox->storage->disk_get(1));  # exception JSON
		# print_r($cnf = $freebox->storage->disk_get(1001)); # exception JSON
		# print_r($cnf = $freebox->storage->disk_get(1000)); # exception JSON
		# print_r($cnf = $freebox->storage->partition_simple(1000)); # exception JSON : method not found.

		break;

	case 'download': 

		print_r($freebox->download->_list());
		print_r($freebox->download->config_get());

		$args = array(
			'max_up' => 90,
			'download_dir' => '/Disque dur/Téléchargements',
			'max_dl' => 2234,
			'max_peer' => 240,
			'seed_ratio' => 2
		);
		# print_r($freebox->download->http_add('ubuntu.iso', 'ftp://ftp.free.fr/mirrors/ftp.ubuntu.com/releases/12.10/ubuntu-12.10-desktop-i386.iso'));
		# print_r($freebox->download->_list());
		$id = 849;
		$type='http';
		# print_r($freebox->download->stop($type, $id));
		# print_r($freebox->download->start($type, $id));
		# print_r($freebox->download->remove($type, $id));
		$url = 'http://ftp.free.fr/mirrors/ftp.ubuntu.com/releases/12.10/ubuntu-12.10-desktop-armhf%2bomap4.img.torrent';
		# print_r($freebox->download->torrent_add($url));

		# print_r($freebox->download->config_get());
		# print_r($freebox->download->config_set($args));
		break;

	case 'conn':
		# print_r($freebox->conn->status());
		var_dump($freebox->conn->remote_access_get());
		# var_dump($freebox->conn->remote_access_set(false));
		break;

	case 'fs':
		print_r($freebox->fs->_list('/Disque dur/Marc'));
		# print_r($freebox->fs->_list('/Disque dur/Maxime', 'with_attr'));
		# print_r($freebox->fs->_list('/', array('with_attr' => true)));

		# $opts = array('with_attr' => 1);
		# $args = array(
		# 	'/Disque dur/',
		# 	$opts
		# );
		# print_r($freebox->exec('fs.list', $args));
		break;

	case 'test': 
	case 'debug': 

		# ethsw.port_state
		# ethsw.mac_address_table
		# ethsw.port_counters
		# ethsw.port_set_config
		print_r($freebox->exec('ethsw.port_state'));

		# $freebox->debug();
		# print_r($cfg = $freebox->ftp->get_config());
		# print_r($freebox->ftp->set_config($cfg));

		break;
}


?>
