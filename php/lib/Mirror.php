<?php

class Mirror extends Mafreebox {
	public function get($file){
		# http://mafreebox.fr/get.php avec le paramètre POST « filename=/Disque dur/chemin/vers/le/fichier ». 
		# wget 'http://mafreebox.freebox.fr/fs.cgi?file=/Disque dur/gros.img'
		$args = array(
		  'filename' =>  $file,
		);
		  
		$res = $this->curl->post(sprintf("%sget.php", $this->addr), $args);
		return $res->body();
	}
	
	public function save($file){
		$data = $this->get($file);
		file_put_contents(basename($file), $data);
	}
	
	public function ls($dir){
		$args = array(
		  'jsonrpc'  => "2.0",
		  'method' =>  "fs.list",
		  # 'id'  => 0.1816119037070476,
		  'params'   => 
			array(
			   $dir,
			   array("with_attr" => true)
		   )
		);

		$headers = array(
		  'Content-Type: application/json; charset=utf-8'
		);

		$args = str_replace('\/', '/', json_encode($args));
		$res = $this->curl->post(sprintf("%sfs.cgi", $this->addr), $args, $headers);

		$res = json_decode($res->body());

		if(isset($res->error))
			throw new Exception("erreur ls : " . $res->error->message);

		return $res->result;
	}
	
	public function mirror($dir){
		
		$files = $this->ls($dir);

		foreach($files as $file){
			if($file->type != 'file')
				continue;

			if(!file_exists($file->name)){
				$this->save($dir . '/' . $file->name);
				printf("- file copied : %s\n", $file->name);
			}
			else
				printf("# file not copied : %s\n", $file->name);
		}
	}
}

?>
