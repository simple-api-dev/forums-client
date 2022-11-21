<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
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
        $validate = Validator::make($request->all(), [
            'author_id' => 'required',
            'status' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/moderators?apikey=' . getenv('API_KEY'), [
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

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }

    /**
     * Show the form for editing the moderator.
     */
    public function edit($forum_id, $forum_slug, $id)
    {
        $response = Http::timeout(3)->get(getenv('API_SITE') . '/moderators/' . $id . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $moderator_content = json_decode($response);

        $statuses = array(
            'Active' => 'Active',
            'Disabled' => 'Disabled',
        );

        return view('editModerator', compact('moderator_content', 'statuses', 'forum_id', 'forum_slug', 'id'));
    }

    /**
     * Call API to update the specified moderator
     */
    public function update(Request $request)
    {
        $request_data = $request->all();
        $response = Http::timeout(3)->put(getenv('API_SITE') . '/moderators/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
                'status' => $request_data['status'],
        ]);

        if ($response->status() <> 200) {
            dd($response);
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }


    /**
     * Call API to remove the specified moderator
     */
    public function destroy($forum_id, $forum_slug, $id)
    {
        $response = Http::timeout(3)->delete(getenv('API_SITE') . '/moderators/' . $id . '?apikey=' . getenv('API_KEY'), []);

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
