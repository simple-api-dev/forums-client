@extends('layout.master')

@section('content')
<h3>Create New Topic</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeTopic" method="POST">
    @csrf

    <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">

    <div>
        <label for="title">Title</label>
        <input type="text" name="title" id="title">
    </div>

    <div>
        <label for="body">Body</label>
        <textarea name="body" id="body" rows="3" cols="40" maxlength="512"></textarea>
    </div>

    <div>
        <label for="type">Type</label>
        <select name="type" id="type">
            <option value="Post">Post</option>
            <option value="Video">Video</option>
            <option value="Url">Url</option>
            <option value="Image">Image</option>
        </select>
    </div>

    <div>
        <label for="status">Status</label>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Draft">Draft</option>
            <option value="Pending Review">Pending Review</option>
            <option value="Locked">Locked</option>
        </select>
    </div>

    <div>
        <label for="author_id">Author Id</label>
        <input type="text" name="author_id" id="author_id">
    </div>

    <div>
        <label for="tags">Tags</label>
        <input type="text" name="tags" id="tags">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection
