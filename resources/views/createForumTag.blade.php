@extends('layout.master')

@section('content')
<h3>Create Forum Tag</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeForumTag" method="POST">
    @csrf

    <input type="hidden" name="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" value="{{$forum_slug}}">

    <div>
        <label for="name">Name</label>
        <div>
        <input type="text" name="name" id="name">
        </div>
    </div>

    <div>
        <label for="status">Status</label>
        <div>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Locked">Locked</option>
        </select>
        </div>
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection




