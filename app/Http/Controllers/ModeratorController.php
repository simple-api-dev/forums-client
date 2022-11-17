<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;

class ModeratorController extends Controller
{
    /**
     * Display the specified forum details
     */
    public function show(string $slug)
    {
    }

    /**
     * Show the form for creating a new moderator.
     */
    public function create()
    {
        return view('createModerator');
    }

    /**
     * Call API to store a newly created moderator
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();

        $response = $httpClient->request('POST', getenv('API_SITE') . '/moderators/?apikey=' . getenv('API_KEY'), [
            'body' => [
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'author_id' => $request_data['author_id'],
            ]
        ]);

        return redirect('/');
    }

    /**
     * Show the form for editing the moderator.
     */
    public function edit($slug)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/moderators/' . $slug . '?apikey=' . getenv('API_KEY'));
        //$statusCode = $response->getStatusCode();
        $moderator_content = $response->getContent();
        $moderator_content = json_decode($moderator_content);

        $statuses = array(
            'Active' => 'Active',
            'Draft' => 'Draft',
            'Removed' => 'Removed',
            'Locked' => 'Locked'
        );

        return view('editModerator', compact('moderator_content', 'statuses'));
    }

    /**
     * Call API to update the specified moderator
     */
    public function update(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();
        $response = $httpClient->request('PUT', getenv('API_SITE') . '/moderators/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
            'body' => [
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'author_id' => $request_data['author_id'],
            ]
        ]);

        return redirect('/');
    }

    /**
     * Call API to remove the specified moderator
     */
    public function destroy($id)
    {
        $httpClient = HttpClient::create();
        $response = $httpClient->request('DELETE', getenv('API_SITE') . '/moderators/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
