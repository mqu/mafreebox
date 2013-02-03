<?php


/* # author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

RRD : extraction des graph RRD (connexion ADSL, signal/bruit, download)


 1) Internet / ADSL / statistiques / connexion ADSL : debit (up, down) et signal sur bruit (snr)
 http://{$url}/rrd.cgi?db=fbxdsl&type=snr&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 http://{$url}/rrd.cgi?db=fbxdsl&type=rate&dir=down&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 http://{$url}/rrd.cgi?db=fbxdsl&type=rate&dir=up&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 
 db=fbxdsl
 period = {hour|day|week}
 type={rate|snr}
 dir={down|up}
 w=650
 h=90
 color1=00ff00&color2=ff0000
 
 
 2) Internet / Statut : mesure débit utilisé (up, down)
 
 http://{$url}/rrd.cgi?db=fbxconnman&dir=up&period=day&w=650&h=90&color1=00ff00&color2=ff0000&ts=1359638606236
 http://{$url}/rrd.cgi?db=fbxconnman&dir=down&period=day&w=650&h=90&color1=00ff00&color2=ff0000&ts=1359638611251
 
 */

class RRD {

    public function rrd_graph($type = 'down', $period = 'day', $dir = 'down') {
        $geometry = 'w=1000&h=200';
        $colors   = '&color1=00ff00&color2=ff0000';
        $extra    = $geometry . $colors;
        
        switch ($type) {
            case 'snr':
                $db  = 'fbxdsl';
                $dir = ''; # not available here
                $url = sprintf("%s?db=%s&type=snr&%s&period=%s", $this->uri('rrd.cgi'), $db, $extra, $period);
                break;
            case 'rate':
                $db  = 'fbxdsl';
                $url = sprintf("%s?db=%s&type=rate&dir=%s&%s&period=%s", $this->uri('rrd.cgi'), $db, $dir, $extra, $period);
                break;
            case 'wan-rate':
                $db  = 'fbxconnman';
                $url = sprintf("%s?db=%s&dir=%s&period=%s&%s", $this->uri('rrd.cgi'), $db, $dir, $period, $extra);
                break;
        }
        
        $curl = new CURL();
        $curl->set_cookie('FBXSID=' . $this->cookies['cookies']);
        return $curl->get($url)->body();
    }
}
?>
