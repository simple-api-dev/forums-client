<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpClient\HttpClient;

class TopicPostController extends Controller
{
    /**
     * Display the specified topic details
     */
    public function show($forum_id, $forum_slug, $topic_id, $topic_slug)
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/topics/' . $topic_slug . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $topic_content = json_decode($response);


        return view('topicPost', compact('topic_content', 'forum_id', 'forum_slug', 'topic_id', 'topic_slug'));
    }

    /**
     * Call API to store a newly created forum
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'body' => 'required',
            'status' => 'required',
            'author_id' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/comments/type/topic/' . $request_data['topic_id']  . '?apikey=' . getenv('API_KEY'), [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'author_id' => $request_data['author_id'],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL',$results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect(getenv('FORUM_CLIENT') . '/topicPost/' . $request_data['forum_id'] . '/' . $request_data['forum_slug'] . '/' . $request_data['topic_id'] . '/' . $request_data['topic_slug']);
    }

    /**
     */
    public function __construct()
    {
    }
}