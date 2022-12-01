<?php

namespace App\Http\Controllers;


class ForumsController extends Controller
{
    public function show()
    {
        $response = $this->apirequest->get(getenv('API_SITE') . '/forums');
        $content = json_decode($response);
        return view('forums', compact('content'));
    }
}
