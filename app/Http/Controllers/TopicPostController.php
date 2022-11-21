<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpClient\HttpClient;

class TopicPostController extends Controller
{
    /**
     * Display the specified forum details
     */
    public function show($id, $slug)
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

        $response = $client->request('GET', getenv('API_SITE') . '/forums/' . $forum_content->id . '/tags?apikey=' . getenv('API_KEY'));
        $tags_content = $response->getContent();
        $tags_content = json_decode($tags_content);

        return view('forum', compact('forum_content', 'moderators_content', 'rules_content', 'topics_content', 'tags_content'));
    }


    /**
     */
    public function __construct()
    {
    }
}
