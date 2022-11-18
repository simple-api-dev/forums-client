<?php

namespace App\Http\Controllers;

use Symfony\Component\HttpClient\HttpClient;

class ForumsController extends Controller
{
    public function show()
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/forums/?apikey=' . getenv('API_KEY'));
        $content = $response->getContent();
        $content = json_decode($content);

        return view('forums', compact('content'));
    }


    /**
     */
    public function __construct()
    {
    }
}
