# List view controller
#
# Fancy description here
#
window.boomboxApp.controller "listingController", ($scope, $http) ->

  # Update sidebar
  $('.views a').removeClass "active"
  $('.sidebar li').removeClass "selected"
  $(".sidebar .link-list-view").addClass "selected"
  $(".views .link-list-view").addClass "active"
  $("#contents").removeClass().addClass "index"

  # Set up events
  Boombox.unloadTempEventListeners()

  # Table cell selection
  lastCell = ''
  $("#table-album-list tbody").on 'click', 'tr', (e) ->
    if e.ctrlKey
      $(this).toggleClass 'active'
      lastCell = $(this) if $(this).hasClass 'active'
    else if e.shiftKey and lastCell? and lastCell isnt ''
      $('#table-album-list tr').between($(this), lastCell).each ->
        lastCell = $(this).addClass 'active'
    else
      $('#table-album-list tr').removeClass 'active'
      lastCell = $(this).addClass 'active'

  $("#table-album-list tbody").on 'dblclick', 'tr', -> Boombox.playSong($(this))
  $("#table-album-list tbody").on 'tap', 'tr', ->
    $('#table-album-list tr').removeClass 'active'
    $(this).toggleClass 'active'
    Boombox.playSong($(this))

  if Boombox.songID?
    Boombox.nowPlaying = $("tr##{Boombox.songID}")
    if Boombox.isPlaying()
      Boombox.nowPlaying.replaceClass('paused', 'playing')
    else
      Boombox.nowPlaying.replaceClass('playing', 'paused')

  # Tag Editing
  $('.edit-button').on 'click', ->
    ids = (n.id for n in $('#table-album-list tr.active'))

    if ids.length > 0
      $.post 'ajax/edit-modal', { query: ids }, (data) ->

        $('body').append data
        modal = $('#modal')
        $scope.$emit "centerRequest"

        # add save and close actions
        $('#modal .close').on 'click', ->
          modal.remove()
          $('#overlay').remove()

        $('#modal .save').on 'click', (e) ->
          e.preventDefault()
          $.post 'ajax/edit', $('#modal #edit').serialize(), (data) ->
            modal.remove()
            $('#overlay').remove()
            $('#container').html(data)

        # multi track edit
        checkboxes = $('#modal input[type="checkbox"]')
        if checkboxes?
          checkboxes.on 'click', ->
            obj = $(this)
            name = obj.attr('name').match(/check\[(\w+)\]/)[1]

            if obj.is(':checked')
              $('input#id3_#{name}').removeAttr('disabled')
            else
              $('input#id3_#{name}').prop('disabled', true)

  # Request data
  $http({
      url: "/api/tracks/all",
      method: "GET"
  }).success (data) ->

    # Set up rowspan array
    rowspan = [1]
    for track, i in data
      if i < data.length - 1
        if track.album == data[i+1].album
          rowspan[rowspan.length - 1] += 1
        else
          rowspan.push 1

    setupCover = (track, i) ->
      coverUrl = track.cover
      row = rowspan.shift()
      cover =  '<div></div>'
      if row > 5
        cover = '<div class="img">'
        cover += '<img src="' + coverUrl + '"/>'
        cover += '</div>'
      track.cover = cover
      track.rowspan = row
      track

    # Go through and set up covers
    for track, i in data
      if i == 0
        track = setupCover(track, i)
      else if track.album != data[i - 1].album
        track = setupCover(track, i)
      else
        track.cover = false
      data[i] = track

    $scope.tracks = data