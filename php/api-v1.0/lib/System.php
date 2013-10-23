<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

System : 

- system.uptime_get() : retourne le temps écoulé depuis la mise en route de la freebox (en secondes)
- system.mac_address_get() : adresse MAC de la FB
- system.serial_get() : n° de série de la FB
- system.reboot ([timeout]) : Redémarre la freebox (timeout = temps d'attente en secondes)
- system.fw_release_get() : renvoie la version courante du firmware

- non documentées :
- system.rotation_set(): 

a faire : récupérer les températures depuis code HTML, page "/settings.php?page=misc_system"

      <li>Température CPUm : <span style="color: black;">XX °C</span></li>
      <li>Température CPUb : <span style="color: black;">XX °C</span></li>
      <li>Température SW : <span style="color: black;">XX °C</span></li>
      <li>Vitesse ventilateur : <span>XXXX RPM</span></li>

*/

class System {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	public function uptime_get(){
		return $this->fb->exec('systeme.uptime_get');
	}
	public function mac_address_get(){
		return $this->fb->exec('systeme.mac_address_get');
	}
	public function serial_get(){
		return $this->fb->exec('systeme.serial');
	}
	public function reboot($timeout){
		return $this->fb->exec('systeme.reboot', $timeout);
	}
	public function fw_release_get(){
		return $this->fb->exec('systeme.fw_release_get');
	}
}
?>
