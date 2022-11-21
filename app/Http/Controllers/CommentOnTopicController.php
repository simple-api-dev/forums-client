<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Symfony\Component\HttpClient\HttpClient;

class CommentOnTopicController extends Controller
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
    public function create($id)
    {
        return view('createTopic', compact('id'));
    }

    /**
     * Call API to store a newly created topic
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'title' => 'title',
            'body' => 'body',
            'status' => 'status',
            'type' => 'type',
            'author_id' => 'author_id',
            'tags' => [],
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();

        $response = Http::timeout(3)->post(getenv('API_SITE') . '/forums/' . $request_data['id'] . '/topics?apikey=' . getenv('API_KEY'), [
                'title' => $request_data['title'],
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'type' => $request_data['type'],
                'author_id' => $request_data['author_id'],
                'tags' => [],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL',$results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect('/');
    }

    /**
     * Show the form for editing the topic.
     */
    public function edit($id)
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/topics/' . $id . '?apikey=' . getenv('API_KEY'));
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
        return view('editComment', compact('statuses', 'types'));
    }

    /**
     * Call API to update the specified topic
     */
    public function update(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'title' => 'title',
            'body' => 'body',
            'status' => 'status',
            'type' => 'type',
            'author_id' => 'author_id',
            'tags' => [],
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->put(getenv('API_SITE') . '/topics/' . $request_data['slug'] . '?apikey=' . getenv('API_KEY'), [
                'title' => $request_data['title'],
                'body' => $request_data['body'],
                'status' => $request_data['status'],
                'type' => $request_data['type'],
                'author_id' => $request_data['author_id'],
                'tags' => [],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL',$results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect('/');
    }


    /**
     * Call API to remove the specified topic
     */
    public function destroy($id)
    {
        $response = Http::timeout(3)->delete(getenv('API_SITE') . '/topics/' . $id . '?apikey=' . getenv('API_KEY'), []);
        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
