<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class ForumTagsController extends Controller
{

    /**
     * Show the form for creating a new tag.
     */
    public function create($forum_id, $forum_slug)
    {
        return view('createForumTag', compact('forum_id', 'forum_slug'));
    }

    /**
     * Call API to store a newly created tag
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'name' => 'required',
            'status' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/tags?apikey=' . getenv('API_KEY'), [
                'name' => $request_data['name'],
                'status' => $request_data['status'],
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
     */
    public function __construct()
    {
    }
}
