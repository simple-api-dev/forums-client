<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;

class ForumController extends Controller
{
    /**
     * Display the specified forum details
     */
    public function show(string $slug)
    {
        $client = HttpClient::create();

        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $slug . '?apikey=' . getenv('API_KEY'));
        $forum_content = $response->getContent();
        $forum_content = json_decode($forum_content);

        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $forum_content->id . '/moderators?apikey=' . getenv('API_KEY'));
        $moderators_content = $response->getContent();
        $moderators_content = json_decode($moderators_content);

        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $forum_content->id . '/rules?apikey=' . getenv('API_KEY'));
        $rules_content = $response->getContent();
        $rules_content = json_decode($rules_content);

        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $slug . '/topics?apikey=' . getenv('API_KEY'));
        $topics_content = $response->getContent();
        $topics_content = json_decode($topics_content);

        return view('forum', compact('forum_content', 'moderators_content', 'rules_content', 'topics_content'));
    }

    /**
     * Show the form for creating a new forum.
     */
    public function create()
    {
        return view('createForum');
    }

    /**
     * Call API to store a newly created forum
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();

        $response = $httpClient->request('POST', getenv('API_SITE') . '/forums/?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json', ],
            'body' => json_encode([
                'title' => $request_data['title'],
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'author_id' => $request_data['author_id'],
            ])
        ]);



        return redirect('/');
    }

    /**
     * Show the form for editing the forum.
     */
    public function edit($slug)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $slug . '?apikey=' . getenv('API_KEY'));
        //$statusCode = $response->getStatusCode();
        $forum_content = $response->getContent();
        $forum_content = json_decode($forum_content);

        $statuses = array(
            'Active' => 'Active',
            'Draft' => 'Draft',
            'Pending Review' => 'Pending Review',
            'Locked' => 'Locked'
        );

        return view('editForum', compact('forum_content', 'statuses'));
    }

    /**
     * Call API to update the specified forum
     */
    public function update(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();
        $response = $httpClient->request('PUT', getenv('API_SITE') . '/forums/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json', ],
            'body' => json_encode([
                'body' => $request_data['body'],
                'status' => $request_data['status'],
            ])
        ]);

        return redirect('/');
    }


    /**
     * Call API to remove the specified forum
     */
    public function destroy($id)
    {
        $httpClient = HttpClient::create();
        $response = $httpClient->request('DELETE', getenv('API_SITE') . '/forums/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
