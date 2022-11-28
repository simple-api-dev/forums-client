<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;

class ForumsController extends Controller
{
    public function show()
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/forums/?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            $msg = (string) $response->getBody();
            dd($msg);
        }
        $content = json_decode($response);
        return view('forums', compact('content'));
    }


    public function __construct()
    {
    }
}
