import { Card, Metric, Subtitle } from '@tremor/react'
import SideMenu from './SideMenu'

function Loader () {
  return (
    <SideMenu>
      <Card>
        <div className='flex items-center justify-center gap-4'>
          <div
            className='inline-block h-16 w-16 animate-spin rounded-full border-4 border-solid border-white border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]'
            role='status'
          >
            <span className='!absolute !-m-px !h-px !w-px !overflow-hidden !whitespace-nowrap !border-0 !p-0 ![clip:rect(0,0,0,0)]'>Loading...
            </span>
          </div>
          <div>
            <Metric>La pagina se esta cargando...</Metric>
            <Subtitle className='mt-4'>Por favor espere, no cierre o recargue la pagina.<br />Hacer esto puede causar perdida de datos.</Subtitle>
          </div>
        </div>
      </Card>
    </SideMenu>
  )
}

export default Loader
