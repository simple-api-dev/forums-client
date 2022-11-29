<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class ForumController extends Controller
{
    /**
     * Display the specified forum details
     */
    public function show($id, $slug)
    {
        $response = Http::get(getenv('API_SITE') . '/forums/' . $slug . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $forum_content = json_decode($response);

        $response = Http::get(getenv('API_SITE') . '/forums/' . $forum_content->id . '/moderators?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $moderators_content = json_decode($response);


        $response = Http::get(getenv('API_SITE') . '/forums/' . $forum_content->id . '/rules?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $rules_content = json_decode($response);

        $response = Http::get(getenv('API_SITE') . '/forums/' . $slug . '/topics?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $topics_content = json_decode($response);

        $response = Http::get(getenv('API_SITE') . '/forums/' . $forum_content->id . '/tags?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $tags_content = json_decode($response);

        return view('forum', compact('forum_content', 'moderators_content', 'rules_content', 'topics_content', 'tags_content'));
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
        $validate = Validator::make($request->all(), [
            'title' => 'required',
            'body' => 'required',
            'status' => 'required',
            'author_id' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::post(getenv('API_SITE') . '/forums/?apikey=' . getenv('API_KEY'), [
            'title' => $request_data['title'],
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
        return redirect('/');
    }

    /**
     * Show the form for editing the forum.
     */
    public function edit($id, $slug)
    {
        $response = Http::get(getenv('API_SITE') . '/forums/' . $slug . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $forum_content = json_decode($response);

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
        $validate = Validator::make($request->all(), [
            'body' => 'required',
            'status' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::put(getenv('API_SITE') . '/forums/' . $request_data['id'] , [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL', $results);
            return back()->withErrors($validate->errors())->withInput();
        }
        return redirect('/');
    }


    /**
     * Call API to remove the specified forum
     */
    public function destroy($id)
    {
        $response = Http::delete(getenv('API_SITE') . '/forums/' . $id , []);
        if ($response->status() <> 200) {
            dd($response);
        }
        return redirect('/');
    }

    /**
     */
}
