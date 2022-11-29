<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;


class commentController extends Controller
{

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

        $response = Http::post(getenv('API_SITE') . '/comments/type/topic/' . $request_data['topic_id']  , [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'author_id' => $request_data['author_id'],
        ]);

        if ($response->status() <> 200) {
            $results = json_decode($response->getBody(), true);
            foreach ($results as $key => $value) {
                $validate->getMessageBag()->add($key, $value);
            }
            return back()->withErrors($validate->errors())->withInput();
        }


        return redirect(getenv('FORUM_CLIENT') . '/topicShow/' . $request_data['forum_id'] . '/' . $request_data['forum_slug'] . '/' . $request_data['topic_id'] . '/' . $request_data['topic_slug']);
    }

    /**
     * Call API to store a newly created forum
     */
    public function storeCommentComment(Request $request)
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
        $response = Http::post(getenv('API_SITE') . '/comments/type/comment/' . $request_data['id']  , [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'author_id' => $request_data['author_id'],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL',$results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect(getenv('FORUM_CLIENT') . '/topicShow/' . $request_data['forum_id'] . '/' . $request_data['forum_slug'] . '/' . $request_data['topic_id'] . '/' . $request_data['topic_slug']);
    }

    /**
     * Call API to remove the topics comment
     */
    public function destroy($forum_id, $forum_slug, $topic_id, $topic_slug, $id)
    {
        $response = Http::delete(getenv('API_SITE') . '/comments/' . $id , []);

        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect(getenv('FORUM_CLIENT') . '/topicShow/' . $forum_id . '/' . $forum_slug . '/' . $topic_id . '/' . $topic_slug);
    }
    /**
     */
    public function __construct()
    {
    }
}
