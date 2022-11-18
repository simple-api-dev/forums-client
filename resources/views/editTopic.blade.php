<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Edit Topic</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Edit Topic</h3>
    <form action="http://127.0.0.1:8000/updateTopic" method="POST" enctype="multipart/form-data">
        @csrf
        <input type="hidden" name="slug" id="slug" value="{{$topic_content->slug}}">

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" class="form-control" name="title" id="title" value="{{$topic_content->title}}">
        </div>

        <div class="form-group">
            <label for="body">Body</label>
            <input type="text" class="form-control" name="body" id="body" value="{{$topic_content->body}}">
        </div>

        <div class="form-group">
            <label for="type">Type</label>
            <select class="form-control" required name="type" id="type">
                @foreach($types  as $key => $value)
                    <option
                        value="{{ $key }}" {{$topic_content->type == $key  ? 'selected' : ''}}>{{ $value}}</option>
                @endforeach
            </select>
        </div>

        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" required name="status" id="status">
                @foreach($statuses  as $key => $value)
                    <option
                        value="{{ $key }}" {{$topic_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
                @endforeach
            </select>
        </div>

        <div class="form-group">
            <label for="author_id">Author_id</label>
            <input type="text" class="form-control" name="author_id" id="author_id" value="{{$topic_content->author_id}}">
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">
    </form>
</div>
</body>

</html>
