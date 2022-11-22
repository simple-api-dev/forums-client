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
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::timeout(3)->post(getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/moderators?apikey=' . getenv('API_KEY'), [
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
