<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;

class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;

    protected $apirequest = null;

    function __construct()
    {
        if(Session::has('token')) {
            $this->apirequest = Http::withHeaders([
                'Authorization' => 'Bearer ' . Session::get('token'),
                'APIKEY' => getenv('API_KEY')
            ]);
        } else {
            $this->apirequest = Http::withHeaders([
                'APIKEY' => getenv('API_KEY')
            ]);
        }
        $this->apirequest->timeout(3);
    }
}
