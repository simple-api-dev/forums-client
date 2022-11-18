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
    public function create($id)
    {
        return view('createRule', compact('id'));
    }

    /**
     * Call API to store a newly created rule
     */
    public function store(Request $request)
    {
        $request_data = $request->all();
        $httpClient = HttpClient::create();


        try {
            $httpClient->request('POST', getenv('API_SITE') . '/forums/' . $request_data['id'] . '/rules?apikey=' . getenv('API_KEY'), [
                'headers' => [
                    'Content-Type' => 'application/json',],
                'body' => json_encode([
                    'author_id' => $request_data['author_id'],
                    'body' => $request_data['body'],
                    'status' => $request_data['status'],
                ])
            ]);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }

        return redirect('/');
    }

    /**
     * Show the form for editing the rule.
     */
    public function edit($id)
    {
        $client = HttpClient::create();
        $response = $client->request('GET', getenv('API_SITE') . '/rules/' . $id . '?apikey=' . getenv('API_KEY'));
        $rule_content = $response->getContent();
        $rule_content = json_decode($rule_content);

        $statuses = array(
            'Active' => 'Active',
            'Disabled' => 'Disabled',
        );


        return view('editRule', compact('rule_content', 'statuses'));
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

        return redirect('/');
    }


    /**
     * Call API to remove the specified rule
     */
    public function destroy($id)
    {
        $httpClient = HttpClient::create();
        try {
            $httpClient->request('DELETE', getenv('API_SITE') . '/rules/' . $id . '?apikey=' . getenv('API_KEY'), []);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }
        return redirect('/');
    }

    /**
     * Call API to remove all forum rule
     */
    public function destroyAll($id)
    {
        $httpClient = HttpClient::create();
        try {
            $httpClient->request('DELETE', getenv('API_SITE') . '/forums/' . $id . '/rules?apikey=' . getenv('API_KEY'), []);
        } catch (TransportExceptionInterface $e) {
            dd($e);
        }
        return redirect('/');
    }

    /**
     */
    public function __construct()
    {
    }
}
