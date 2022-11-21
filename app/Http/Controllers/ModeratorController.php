<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;

class ModeratorController extends Controller
{
    /**
     * Display the specified forum details
     */
    public function show()
    {
    }

    /**
     * Show the form for creating a new moderator.
     */
    public function create($forum_id, $forum_slug)
    {
        return view('createModerator', compact('forum_id', 'forum_slug'));
    }

    /**
     * Call API to store a newly created moderator
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();


        $httpClient->request('POST', getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/moderators?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json',],
            'body' => json_encode([
                'status' => $request_data['status'],
                'author_id' => $request_data['author_id'],
            ])
        ]);

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }

    /**
     * Show the form for editing the moderator.
     */
    public function edit($forum_id, $forum_slug, $id)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/moderators/' . $id . '?apikey=' . getenv('API_KEY'));
        $moderator_content = $response->getContent();
        $moderator_content = json_decode($moderator_content);

        $statuses = array(
            'Active' => 'Active',
            'Disabled' => 'Disabled',
        );

        return view('editModerator', compact('moderator_content', 'statuses','forum_id', 'forum_slug', 'id'));
    }

    /**
     * Call API to update the specified moderator
     */
    public function update(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();
        $httpClient->request('PUT', getenv('API_SITE') . '/moderators/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
            'headers' => [
                'Content-Type' => 'application/json',],
            'body' => json_encode([
                'status' => $request_data['status'],
            ])
        ]);

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }


    /**
     * Call API to remove the specified moderator
     */
    public function destroy($forum_id, $forum_slug, $id)
    {
        $httpClient = HttpClient::create();
        $httpClient->request('DELETE', getenv('API_SITE') . '/moderators/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     */
    public function __construct()
    {
    }
}
