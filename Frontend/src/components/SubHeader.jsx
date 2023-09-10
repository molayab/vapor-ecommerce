import Breadcrumb from './Breadcrumb'
import { useLocation } from 'react-router-dom'

function SubHeader () {
  const router = useLocation()
  const parts = router.pathname.split('/')

  return (
    <div className='hidden sm:block'>
      <Breadcrumb pathArray={parts} />
    </div>
  )
}

export default SubHeader
