<?php

namespace App\Http\Controllers;


use Illuminate\Support\Facades\Http;

class topicShowController extends Controller
{
    /**
     * Display the specified topic details
     */
    public function show($forum_id, $forum_slug, $topic_id, $topic_slug)
    {
        $response = Http::get(getenv('API_SITE') . '/topics/' . $topic_slug . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $topic_content = json_decode($response);

        $comments = $topic_content->comments;

        return view('topicShow', compact('topic_content', 'forum_id', 'forum_slug', 'topic_id', 'topic_slug', 'comments'));
    }
}
