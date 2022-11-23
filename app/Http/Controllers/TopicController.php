<?php

namespace App\Http\Controllers;

use http\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class TopicController extends Controller
{
    /**
     * Display the specified topic details
     */
    public function show()
    {
    }

    /**
     * Show the form for creating a new topic.
     */
    public function create($forum_id, $forum_slug)
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/forums/' . $forum_id . '/tags?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $tags = json_decode($response);

        return view('createTopic', compact('forum_id', 'forum_slug', 'tags'));
    }

    /**
     * Call API to store a newly created topic
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'title' => 'required',
            'body' => 'required',
            'status' => 'required',
            'type' => 'required',
            'author_id' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $tags = [];
        if (isset($request_data['tags'])) {
            $tags = $request_data['tags'];
        }
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/topics?apikey=' . getenv('API_KEY'), [
            'title' => $request_data['title'],
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'type' => $request_data['type'],
            'author_id' => $request_data['author_id'],
            'tags' => $tags,
        ]);

        if ($response->status() <> 200) {
            $results = json_decode($response->getBody(), true);
            foreach ($results as $key => $value) {
                $validate->getMessageBag()->add($key, $value);
            }
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }

    /**
     * Show the form for editing the topic.
     */
    public function edit($forum_id, $forum_slug, $slug)
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/forums/' . $forum_id . '/tags?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $tags = json_decode($response);

        $response = Http::timeout(3)->get(getenv('API_SITE') . '/topics/' . $slug . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $topic_content = json_decode($response);


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
        return view('editTopic', compact('topic_content', 'statuses', 'types', 'forum_id', 'forum_slug', 'tags'));
    }

    /**
     * Call API to update the specified topic
     */
    public function update(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'body' => 'required',
            'status' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $tags = [];
        if (isset($request_data['tags'])) {
            $tags = $request_data['tags'];
        }
        $response = Http::timeout(3)->put(getenv('API_SITE') . '/topics/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'tags' => $tags,
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL', $results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }


    /**
     * Call API to remove the specified topic
     */
    public function destroy($forum_id, $forum_slug, $id)
    {
        $response = Http::timeout(3)->delete(getenv('API_SITE') . '/topics/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }


    /**
     * Call API to upvote the specified topic
     */
    public function upvote($forum_id, $forum_slug, $id)
    {
        try {
            $response = Http::timeout(3)->post(getenv('API_SITE') . '/votes/up/topic/' . $id . '?apikey=' . getenv('API_KEY'), [
                'author_id' => "DAN-3",
            ]);
        } catch (\Exception $e){
            dd($e->getMessage());
        }
        if ($response->status() <> 200) {
            dd($response);
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to downvote the specified topic
     */
    public function downvote($forum_id, $forum_slug, $id)
    {
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/votes/down/topic/' . $id . '?apikey=' . getenv('API_KEY'), [
            'author_id' => "JO-22",
        ]);
        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }


    /**
     */
    public function __construct()
    {
    }
}
