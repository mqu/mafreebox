<?php

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 
#
# Curl, CurlResponse
#
# Author Sean Huber - shuber@huberry.com
# Date May 2008
#
# A basic CURL wrapper for PHP
#
# See the README for documentation/examples or http://php.net/curl for more information about the libcurl extension for PHP
 
class Curl
{
    public $cookie_file;
    public $headers = array();
    public $options = array();
    public $referer = '';
    public $user_agent = '';
 
    protected $error = '';
    protected $handle;
 
 
    public function __construct()
    {
        $this->cookie_file = './cookie.txt';
        $this->user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3';

        $this->handle = curl_init();
        $this->set_defaults_opts();
    }
 
    public function __destroy(){
		echo "destroy\n";
		$this->close();
	}

	public function close(){
		curl_close($this->handle);
	}

    public function delete($url, $vars = array())
    {
        return $this->request('DELETE', $url, $vars);
    }
 
    public function error()
    {
        return $this->error;
    }
 
    public function get($url, $vars = array(), $headers=array())
    {
        if (!empty($vars)) {
            $url .= (stripos($url, '?') !== false) ? '&' : '?';
            $url .= http_build_query($vars, '', '&');
        }
        return $this->request('GET', $url, $headers);
    }
 
    public function post($url, $vars = array(), $headers=array())
    {
        return $this->request('POST', $url, $vars, $headers);
    }
 
    public function put($url, $vars = array())
    {
        return $this->request('PUT', $url, $vars);
    }

    protected function set_defaults_opts($vars = null){
        # Set some default CURL options
        curl_setopt($this->handle, CURLOPT_COOKIEFILE, $this->cookie_file);
        curl_setopt($this->handle, CURLOPT_COOKIEJAR, $this->cookie_file);
        curl_setopt($this->handle, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($this->handle, CURLOPT_HEADER, true);
        curl_setopt($this->handle, CURLOPT_REFERER, $this->referer);
        curl_setopt($this->handle, CURLOPT_RETURNTRANSFER, true);
        # curl_setopt($this->handle, CURLOPT_URL, $url);
        curl_setopt($this->handle, CURLOPT_USERAGENT, $this->user_agent);
		# curl_setopt($this->handle, CURLOPT_VERBOSE, TRUE);  # verbose, debug
	}

	public function setopt($name, $value){
		# echo "Curl::setopt($name, $value)\n";
		# print_r($value);
		$status = curl_setopt($this->handle, $name, $value);
		if($status == false)
			die("error on setopt($name, $value)");
	}

	public function set_cookie($cookie){
		curl_setopt($this->handle, CURLOPT_COOKIE, $cookie);
	}

	public function set_verbose($bool=true){
		$this->setopt(CURLOPT_VERBOSE, $bool);
	}

    public function request($method, $url, $vars = array(), $headers=array())
    {

        # Format custom headers for this request and set CURL option
        # $headers = array();
        # foreach ($this->headers as $key => $value) {
        #    $headers[] = $key.': '.$value;
        # }

        curl_setopt($this->handle, CURLOPT_HTTPHEADER, $headers);
		$this->setopt(CURLOPT_URL, $url);

        # Determine the request method and set the correct CURL option
        switch ($method) {
            case 'GET':
                curl_setopt($this->handle, CURLOPT_HTTPGET, true);
                break;
            case 'POST':
                curl_setopt($this->handle, CURLOPT_POST, true);
				curl_setopt($this->handle, CURLOPT_POSTFIELDS, (is_array($vars) ? http_build_query($vars, '', '&') : $vars));
                break;
            default:
                curl_setopt($this->handle, CURLOPT_CUSTOMREQUEST, $method);
        }

        # Set any custom CURL options
        foreach ($this->options as $option => $value) {
            curl_setopt($this->handle, constant('CURLOPT_'.str_replace('CURLOPT_', '', strtoupper($option))), $value);
        }

        $response = curl_exec($this->handle);
		# printf("url : [%s] : %s\n", $method, $url) ; print_r($response);

        if ($response === false) {
            $this->error = curl_errno($this->handle).' - '.curl_error($this->handle);
			throw new Exception ('connexion error');
			die ("erreur concernant la requete sur le site ; v�rifier la connexion au PROXY, l'acces au site ...");
        } else {
            $response = new CurlResponse($response);
        }
        # curl_close($this->handle);
        return $response;
    }
}
 
class CurlResponse
{
    public $body = '';
    public $headers = array();
 
    public function __construct($response)
    {
        # Extract headers from response
        $pattern = '#HTTP/\d\.\d.*?$.*?\r\n\r\n#ims';
        preg_match_all($pattern, $response, $matches);
        $headers = explode("\r\n", str_replace("\r\n\r\n", '', array_pop($matches[0])));
        
        # Extract the version and status from the first header
        $version_and_status = array_shift($headers);
        preg_match('#HTTP/(\d\.\d)\s(\d\d\d)\s(.*)#', $version_and_status, $matches);
        $this->headers['Http-Version'] = $matches[1];
        $this->headers['Status-Code'] = $matches[2];
        $this->headers['Status'] = $matches[2].' '.$matches[3];
        
        # Convert headers into an associative array
        foreach ($headers as $header) {
            preg_match('#(.*?)\:\s(.*)#', $header, $matches);
            $this->headers[$matches[1]] = $matches[2];
        }
        
        # Remove the headers from the response body
        $this->body = preg_replace($pattern, '', $response);
    }
 
    public function __toString()
    {
        return $this->body;
    }

	public function body(){
        return $this->body;
	}

	public function headers(){
        return $this->headers;
	}
}

