<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpClient\HttpClient;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

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
        $request_data = $request->all();
        $httpClient = HttpClient::create();


            $httpClient->request('POST', getenv('API_SITE') . '/forums/' . $request_data['forum_id'] . '/rules?apikey=' . getenv('API_KEY'), [
                'headers' => [
                    'Content-Type' => 'application/json',],
                'body' => json_encode([
                    'author_id' => $request_data['author_id'],
                    'body' => $request_data['body'],
                    'status' => $request_data['status'],
                ])
            ]);

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }

    /**
     * Show the form for editing the rule.
     */
    public function edit($forum_id, $forum_slug, $id)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/rules/' . $id . '?apikey=' . getenv('API_KEY'));
        $rule_content = $response->getContent();
        $rule_content = json_decode($rule_content);

        $statuses = array(
            'Active' => 'Active',
            'Disabled' => 'Disabled',
        );


        return view('editRule', compact('rule_content', 'statuses', 'id', 'forum_id', 'forum_slug'));
    }

    /**
     * Call API to update the specified rule
     */
    public function update(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();
        try {
            $httpClient->request('PUT', getenv('API_SITE') . '/rules/' . $request_data['id'] . '?apikey=' . getenv('API_KEY'), [
                'headers' => [
                    'Content-Type' => 'application/json',],
                'body' => json_encode([
                    'body' => $request_data['body'],
                    'status' => $request_data['status'],
                    'author_id' => $request_data['author_id'],
                ])
            ]);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }

        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $request_data['forum_id'] . '/' . $request_data['forum_slug']);
    }


    /**
     * Call API to remove the specified rule
     */
    public function destroy($forum_id, $forum_slug, $id)
    {
        $httpClient = HttpClient::create();
        try {
            $httpClient->request('DELETE', getenv('API_SITE') . '/rules/' . $id . '?apikey=' . getenv('API_KEY'), []);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     * Call API to remove all forum rule
     */
    public function destroyAll($forum_id, $forum_slug)
    {
        $httpClient = HttpClient::create();
        try {
            $httpClient->request('DELETE', getenv('API_SITE') . '/forums/' . $forum_id . '/rules?apikey=' . getenv('API_KEY'), []);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }
        return redirect(getenv('FORUM_CLIENT') . '/forum/' . $forum_id . '/' . $forum_slug);
    }

    /**
     */
    public function __construct()
    {
    }
}
