<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class LoginUserController extends Controller
{
    public function create()
    {
        return view('auth.login');
    }


    public function store(Request $request)
    {
        //$request->authenticate();
        //$request->session()->regenerate();
        //return redirect()->intended(RouteServiceProvider::HOME);
        return redirect(getenv('FORUM_CLIENT'));
    }


    public function destroy(Request $request)
    {
        //Auth::guard('web')->logout();
        //$request->session()->invalidate();
        //$request->session()->regenerateToken();
        return redirect('/');
    }
}
