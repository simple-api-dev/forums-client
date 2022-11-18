<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;

class TopicController extends Controller
{
    /**
     * Display the specified topic details
     */
    public function show(string $slug)
    {
    }

    /**
     * Show the form for creating a new topic.
     */
    public function create($id)
    {
        return view('createTopic', compact('id'));
    }

    /**
     * Call API to store a newly created topic
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();


        $httpClient->request('POST', getenv('API_SITE') . '/forums/' . $request_data['id'] . '/topics?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json',],
            'body' => json_encode([
                'title' => $request_data['title'],
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'type' => $request_data['type'],
                'author_id' => $request_data['author_id'],
                'tags' => [],
            ])
        ]);
        return redirect('/');
    }

    /**
     * Show the form for editing the topic.
     */
    public function edit($slug)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/topics/' . $slug . '?apikey=' . getenv('API_KEY'));
        $topic_content = $response->getContent();
        $topic_content = json_decode($topic_content);

        $types = array(
            'Post' => 'Post',
            'Video' => 'Video',
            'Url' => 'Url',
            'Image' => 'Image',
        );
        $statuses = array(
            'Active' => 'Active',
            'Draft' => 'Draft',
            'Pending Review' => 'Pending Review',
            'Locked' => 'Locked',
        );
        return view('editTopic', compact('topic_content', 'statuses', 'types'));
    }

    /**
     * Call API to update the specified topic
     */
    public function update(Request $request)
    {
        $request_data = $request->all();

        $httpClient = HttpClient::create();
        $httpClient->request('PUT', getenv('API_SITE') . '/topics/' . $request_data['slug'] . '?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json',],
            'body' => json_encode([
                'title' => $request_data['title'],
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'type' => $request_data['type'],
                'author_id' => $request_data['author_id'],
                'tags' => [],
            ])
        ]);
        return redirect('/');
    }


    /**
     * Call API to remove the specified topic
     */
    public function destroy($id)
    {
        $httpClient = HttpClient::create();
        $httpClient->request('DELETE', getenv('API_SITE') . '/topics/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
