<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class RuleController extends Controller
{
    /**
     * Display the specified rule details
     */
    public function show(string $slug)
    {
    }

    /**
     * Show the form for creating a new rule.
     */
    public function create($forum_id, $forum_slug)
    {
        return view('createRule', compact('forum_id', 'forum_slug'));
    }

    /**
     * Call API to store a newly created rule
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'body' => 'required',
            'author_id' => 'required',
            'status' => 'required',
        ]);

        if ($validate->fails()) {
            return back()->withErrors($validate->errors())->withInput();
        }

        $request_data = $request->all();
        $response = Http::post(getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/rules?apikey=' . getenv('API_KEY'), [
                'author_id' => $request_data['author_id'],
                'body' => $request_data['body'],
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
     * Show the form for editing the rule.
     */
    public function edit($forum_id, $forum_slug, $id)
    {
        $response = Http::get(getenv('API_SITE') . '/rules/' . $id . '?apikey=' . getenv('API_KEY'));
        if ($response->status() <> 200) {
            dd($response);
        }
        $rule_content = json_decode($response);

        $statuses = array(
            'Active' => 'Active',
            'Draft' => 'Draft',
            'Disabled' => 'Disabled',
        );

        return view('editRule', compact('rule_content', 'statuses', 'id', 'forum_id', 'forum_slug'));
    }

    /**
     * Call API to update the specified rule
     */
    public function update(Request $request)
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
        $response = Http::put(getenv('API_SITE') . '/rules/' . $request_data['id'] , [
            'body' => $request_data['body'],
            'status' => $request_data['status'],
            'author_id' => $request_data['author_id'],
        ]);

        if (!$response->successful()) {
            $results = json_decode($response->getBody(), true);
            $validate->getMessageBag()->add('HTTP-FAIL', $results);
            return back()->withErrors($validate->errors())->withInput();
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }


    /**
     * Call API to remove the specified rule
     */
    public function destroy($forum_id, $forum_slug, $id)
    {
        $response = Http::delete(getenv('API_SITE') . '/rules/' . $id , []);
        if ($response->status() <> 200) {
            dd($response);
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to remove all forum rule
     */
    public function destroyAll($forum_id, $forum_slug)
    {
        $response = Http::delete(getenv('API_SITE') . '/forums/' . $forum_id . '/rules?apikey=' . getenv('API_KEY'), []);
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
