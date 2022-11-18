<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;

class ForumTagsController extends Controller
{

    /**
     * Show the form for creating a new tag.
     */
    public function create(Request $request)
    {
        $id = $request->id;

        return view('createForumTag', compact('id'));
    }

    /**
     * Call API to store a newly created tag
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();

        $httpClient->request('POST', getenv('API_SITE') . '/forums/' . $request_data['id'] . '/tags?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json', ],
            'body' => json_encode([
                'name' => $request_data['name'],
                'status' => $request_data['status'],
            ])
        ]);

        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
